//
//  BackendLLMClient.swift
//  OHeas
//
//  LLM client that proxies through the OHeas backend (server-side API key).
//  通过 OHeas 后端代理的 LLM 客户端（服务端持有 API 密钥）。
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// LLM client that calls the OHeas backend proxy instead of calling
/// DeepSeek/OpenAI directly. Requires a configured backend (JWT token).
///
/// The backend holds the API key server-side — the iOS client only sends
/// user messages and the user's JWT for authentication.
public final class BackendLLMClient: LLMClientProtocol, LLMStreaming, @unchecked Sendable {
    public let name = "backend_proxy"

    private let baseURL: URL
    private let bearerToken: String
    private let session: URLSession

    public init(
        baseURL: URL,
        bearerToken: String,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.bearerToken = bearerToken
        self.session = session
    }

    // MARK: - One-shot recommendation

    public func generateRecommendationJSON(payload: CoachPromptPayload) async throws -> String {
        let url = baseURL.appendingPathComponent("v1/llm/recommendation")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "system_prompt": payload.systemPrompt,
            "user_context_json": payload.userContextJSON,
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw LLMClientError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            let bodyStr = String(data: data, encoding: .utf8) ?? ""
            if http.statusCode == 503 {
                throw LLMClientError.httpStatus(503, "Backend LLM service not configured")
            }
            throw LLMClientError.httpStatus(http.statusCode, bodyStr)
        }

        // Backend returns { "content": "<raw LLM response>", "model": "..." }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? String else {
            throw LLMClientError.invalidResponse
        }
        return content
    }

    // MARK: - Streaming recommendation

    public func streamRecommendation(payload: CoachPromptPayload) -> AsyncThrowingStream<LLMStreamEvent, Error> {
        // Delegate to chat() with a system+user message pair.
        // The backend /v1/llm/chat endpoint handles both use cases uniformly.
        let messages: [[String: String]] = [
            ["role": "system", "content": payload.systemPrompt],
            ["role": "user", "content": payload.userContextJSON],
        ]
        return chat(messages: messages)
    }

    // MARK: - Chat streaming

    public func chat(messages: [[String: String]]) -> AsyncThrowingStream<LLMStreamEvent, Error> {
        let url = baseURL.appendingPathComponent("v1/llm/chat")

        let body: [String: Any] = [
            "messages": messages,
            "temperature": 0.7,
        ]
        guard let bodyData = try? JSONSerialization.data(withJSONObject: body) else {
            return AsyncThrowingStream { continuation in
                continuation.finish(throwing: LLMClientError.invalidResponse)
            }
        }

        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.httpBody = bodyData

                    let (bytes, response) = try await session.bytes(for: request)
                    guard let http = response as? HTTPURLResponse else {
                        throw LLMClientError.invalidResponse
                    }
                    guard (200..<300).contains(http.statusCode) else {
                        var errorBody = ""
                        for try await line in bytes.lines {
                            errorBody += line
                        }
                        throw LLMClientError.httpStatus(http.statusCode, errorBody)
                    }

                    // Parse SSE stream — same format as ChatCompletionsClient.sseStream()
                    // since the backend passes through upstream SSE lines verbatim.
                    var accumulated = ""
                    for try await line in bytes.lines {
                        guard line.hasPrefix("data: ") else { continue }
                        let data = String(line.dropFirst(6))
                        if data == "[DONE]" {
                            continuation.yield(LLMStreamEvent(
                                token: "", isComplete: true, accumulatedText: accumulated
                            ))
                            continuation.finish()
                            return
                        }
                        guard let jsonData = data.data(using: .utf8),
                              let obj = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                              let choices = obj["choices"] as? [[String: Any]],
                              let delta = choices.first?["delta"] as? [String: Any],
                              let content = delta["content"] as? String
                        else { continue }

                        accumulated += content
                        continuation.yield(LLMStreamEvent(
                            token: content, isComplete: false, accumulatedText: accumulated
                        ))
                    }
                    // Stream ended without [DONE] — finalize anyway
                    continuation.yield(LLMStreamEvent(
                        token: "", isComplete: true, accumulatedText: accumulated
                    ))
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }
}
