//
//  LLMClient.swift
//  OHeas
//
//  LLM client abstraction — OpenAI, Chat Completions (DeepSeek), streaming, mock.
//  LLM 客户端抽象 — OpenAI、Chat Completions（DeepSeek）、流式、模拟。
//


import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public protocol LLMClientProtocol: Sendable {
    var name: String { get }
    func generateRecommendationJSON(payload: CoachPromptPayload) async throws -> String
}

// MARK: - Streaming types

public struct LLMStreamEvent: Sendable {
    public let token: String
    public let isComplete: Bool
    public let accumulatedText: String

    public init(token: String, isComplete: Bool, accumulatedText: String) {
        self.token = token
        self.isComplete = isComplete
        self.accumulatedText = accumulatedText
    }
}

public protocol LLMStreaming: Sendable {
    func streamRecommendation(payload: CoachPromptPayload) -> AsyncThrowingStream<LLMStreamEvent, Error>
    func chat(messages: [[String: String]]) -> AsyncThrowingStream<LLMStreamEvent, Error>
}

public enum LLMClientError: Error, LocalizedError, Sendable {
    case missingAPIKey
    case invalidResponse
    case httpStatus(Int, String)

    public var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            "API key is missing."
        case .invalidResponse:
            "The LLM response could not be read."
        case .httpStatus(let status, let body):
            "LLM request failed with HTTP \(status): \(body)"
        }
    }
}

// MARK: - Chat Completions API Client (DeepSeek, Groq, and other OpenAI-compatible providers)

public final class ChatCompletionsClient: LLMClientProtocol, LLMStreaming, @unchecked Sendable {
    public let name: String

    private let apiKey: String
    private let model: String
    private let endpoint: URL
    private let session: URLSession

    public init(
        apiKey: String,
        model: String = "deepseek-chat",
        endpoint: URL = URL(string: "https://api.deepseek.com/v1/chat/completions")!,
        session: URLSession = .shared,
        name: String = "deepseek"
    ) {
        self.apiKey = apiKey
        self.model = model
        self.endpoint = endpoint
        self.session = session
        self.name = name
    }

    // MARK: - One-shot (non-streaming)

    public func generateRecommendationJSON(payload: CoachPromptPayload) async throws -> String {
        guard !apiKey.isEmpty else {
            throw LLMClientError.missingAPIKey
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: chatCompletionsBody(payload: payload, stream: false))

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw LLMClientError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw LLMClientError.httpStatus(http.statusCode, body)
        }

        let decoded = try JSONDecoder().decode(ChatCompletionsResponse.self, from: data)
        guard let text = decoded.firstContent else {
            throw LLMClientError.invalidResponse
        }
        return text
    }

    // MARK: - Streaming (SSE)

    public func streamRecommendation(payload: CoachPromptPayload) -> AsyncThrowingStream<LLMStreamEvent, Error> {
        let body = chatCompletionsBody(payload: payload, stream: true)
        guard let bodyData = try? JSONSerialization.data(withJSONObject: body) else {
            return AsyncThrowingStream { continuation in
                continuation.finish(throwing: LLMClientError.invalidResponse)
            }
        }
        return sseStream(bodyData: bodyData)
    }

    /// General chat streaming for multi-turn conversations.
    /// - Parameter messages: Array of `["role": "...", "content": "..."]` dicts.
    public func chat(messages: [[String: String]]) -> AsyncThrowingStream<LLMStreamEvent, Error> {
        let body: [String: Any] = [
            "model": model,
            "messages": messages,
            "stream": true,
            "temperature": 0.7
        ]
        // Serialize to Data upfront — Data is Sendable, [String: Any] is not.
        guard let bodyData = try? JSONSerialization.data(withJSONObject: body) else {
            return AsyncThrowingStream { continuation in
                continuation.finish(throwing: LLMClientError.invalidResponse)
            }
        }
        return sseStream(bodyData: bodyData)
    }

    /// Shared SSE streaming implementation. Accepts pre-serialized body data for Sendable safety.
    private func sseStream(bodyData: Data) -> AsyncThrowingStream<LLMStreamEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    guard !apiKey.isEmpty else {
                        throw LLMClientError.missingAPIKey
                    }

                    var request = URLRequest(url: endpoint)
                    request.httpMethod = "POST"
                    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
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

                    var accumulated = ""
                    for try await line in bytes.lines {
                        guard line.hasPrefix("data: ") else { continue }
                        let data = String(line.dropFirst(6))
                        if data == "[DONE]" {
                            continuation.yield(LLMStreamEvent(token: "", isComplete: true, accumulatedText: accumulated))
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
                        continuation.yield(LLMStreamEvent(token: content, isComplete: false, accumulatedText: accumulated))
                    }
                    // Stream ended without [DONE]
                    continuation.yield(LLMStreamEvent(token: "", isComplete: true, accumulatedText: accumulated))
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

    // MARK: - Request body

    private func chatCompletionsBody(payload: CoachPromptPayload, stream: Bool) -> [String: Any] {
        let messages: [[String: String]] = [
            ["role": "system", "content": payload.systemPrompt],
            ["role": "user", "content": payload.userContextJSON]
        ]

        var body: [String: Any] = [
            "model": model,
            "messages": messages,
            "stream": stream
        ]

        if !stream {
            body["response_format"] = ["type": "json_object"]
        }

        return body
    }
}

private struct ChatCompletionsResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            var content: String?
        }
        var message: Message?
    }

    var choices: [Choice]?

    var firstContent: String? {
        choices?.first?.message?.content
    }
}

#if DEBUG
public struct MockLLMClient: LLMClientProtocol, LLMStreaming {
    public let name = "mock_llm"

    public init() {}

    public func generateRecommendationJSON(payload: CoachPromptPayload) async throws -> String {
        Self.mockResponseJSON
    }

    public func streamRecommendation(payload: CoachPromptPayload) -> AsyncThrowingStream<LLMStreamEvent, Error> {
        AsyncThrowingStream { continuation in
            let text = Self.mockResponseJSON
            let tokens = stride(from: 0, to: text.count, by: 3).map { idx in
                let end = min(idx + 3, text.count)
                let startIdx = text.index(text.startIndex, offsetBy: idx)
                let endIdx = text.index(text.startIndex, offsetBy: end)
                return String(text[startIdx..<endIdx])
            }

            Task {
                var accumulated = ""
                for token in tokens {
                    accumulated += token
                    continuation.yield(LLMStreamEvent(token: token, isComplete: false, accumulatedText: accumulated))
                    try? await Task.sleep(nanoseconds: 30_000_000) // 30ms per token for realistic feel
                }
                continuation.yield(LLMStreamEvent(token: "", isComplete: true, accumulatedText: accumulated))
                continuation.finish()
            }
        }
    }

    public func chat(messages: [[String: String]]) -> AsyncThrowingStream<LLMStreamEvent, Error> {
        AsyncThrowingStream { continuation in
            let text = "I'm your health coach (mock mode). I can help answer basic health questions based on the data you've shared. For more detailed advice, connect to the AI service."
            let tokens = stride(from: 0, to: text.count, by: 3).map { idx in
                let end = min(idx + 3, text.count)
                let startIdx = text.index(text.startIndex, offsetBy: idx)
                let endIdx = text.index(text.startIndex, offsetBy: end)
                return String(text[startIdx..<endIdx])
            }

            Task {
                var accumulated = ""
                for token in tokens {
                    accumulated += token
                    continuation.yield(LLMStreamEvent(token: token, isComplete: false, accumulatedText: accumulated))
                    try? await Task.sleep(nanoseconds: 30_000_000)
                }
                continuation.yield(LLMStreamEvent(token: "", isComplete: true, accumulatedText: accumulated))
                continuation.finish()
            }
        }
    }

    private static let mockResponseJSON = """
        {
          "id": "\(UUID().uuidString)",
          "date": "\(ISO8601DateFormatter.oheasString(from: Date()))",
          "state": "balanced",
          "confidence": "Medium",
          "title": "Mock balanced recommendation",
          "summary": "This mock response proves the structured recommendation path works without a network request.",
          "evidence": [
            {
              "id": "\(UUID().uuidString)",
              "metric": "mock",
              "observation": "Mock LLM path was used.",
              "baselineComparison": "No live model call was made.",
              "importance": "Useful for local demos and UI testing."
            }
          ],
          "recommendation": "Take one easy 10-minute walk today.",
          "tonightAction": "Keep a steady bedtime window tonight.",
          "tomorrowVerification": [
            {
              "id": "\(UUID().uuidString)",
              "metric": "subjectiveEnergy",
              "expectedDirection": "increase_or_stable",
              "reason": "Energy feedback verifies whether the action felt sustainable."
            }
          ],
          "followupQuestion": null,
          "safetyNote": "Lifestyle guidance only. This is not a medical diagnosis.",
          "createdAt": "\(ISO8601DateFormatter.oheasString(from: Date()))"
        }
        """
}
#endif

public final class OpenAIClient: LLMClientProtocol, @unchecked Sendable {
    public let name = "openai"

    private let apiKey: String
    private let model: String
    private let endpoint: URL
    private let session: URLSession

    public init(
        apiKey: String,
        model: String = "gpt-5.4-mini",
        endpoint: URL = URL(string: "https://api.openai.com/v1/responses")!,
        session: URLSession = .shared
    ) {
        self.apiKey = apiKey
        self.model = model
        self.endpoint = endpoint
        self.session = session
    }

    public func generateRecommendationJSON(payload: CoachPromptPayload) async throws -> String {
        guard !apiKey.isEmpty else {
            throw LLMClientError.missingAPIKey
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody(payload: payload))

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw LLMClientError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw LLMClientError.httpStatus(http.statusCode, body)
        }

        let decoded = try JSONDecoder().decode(OpenAIResponsesEnvelope.self, from: data)
        guard let text = decoded.outputText else {
            throw LLMClientError.invalidResponse
        }
        return text
    }

    private func requestBody(payload: CoachPromptPayload) -> [String: Any] {
        [
            "model": model,
            "input": [
                [
                    "role": "system",
                    "content": payload.systemPrompt
                ],
                [
                    "role": "user",
                    "content": payload.userContextJSON
                ]
            ],
            "text": [
                "format": CoachRecommendationSchema.openAIJSONSchema
            ]
        ]
    }
}

private struct OpenAIResponsesEnvelope: Decodable {
    struct OutputItem: Decodable {
        struct ContentItem: Decodable {
            var text: String?
        }
        var content: [ContentItem]?
    }

    var outputText: String?
    var output: [OutputItem]?

    enum CodingKeys: String, CodingKey {
        case outputText = "output_text"
        case output
    }

    var resolvedText: String? {
        outputText ?? output?.compactMap { item in
            item.content?.compactMap(\.text).joined()
        }.joined()
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        outputText = try container.decodeIfPresent(String.self, forKey: .outputText)
        output = try container.decodeIfPresent([OutputItem].self, forKey: .output)
        outputText = outputText ?? resolvedText
    }
}

public enum CoachRecommendationSchema {
    public static var openAIJSONSchema: [String: Any] {
        [
            "type": "json_schema",
            "name": "coach_recommendation",
            "strict": true,
            "schema": schema
        ]
    }

    public static var schema: [String: Any] {
        [
            "type": "object",
            "additionalProperties": false,
            "required": [
                "id", "date", "state", "confidence", "title", "summary", "evidence",
                "recommendation", "tonightAction", "tomorrowVerification",
                "followupQuestion", "safetyNote", "createdAt"
            ],
            "properties": [
                "id": ["type": "string", "format": "uuid"],
                "date": ["type": "string", "format": "date-time"],
                "state": ["type": "string", "enum": CoachState.allCases.map(\.rawValue)],
                "confidence": ["type": "string", "enum": ConfidenceLevel.allCasesRawValues],
                "title": ["type": "string"],
                "summary": ["type": "string"],
                "evidence": [
                    "type": "array",
                    "items": [
                        "type": "object",
                        "additionalProperties": false,
                        "required": ["id", "metric", "observation", "baselineComparison", "importance"],
                        "properties": [
                            "id": ["type": "string", "format": "uuid"],
                            "metric": ["type": "string"],
                            "observation": ["type": "string"],
                            "baselineComparison": ["type": "string"],
                            "importance": ["type": "string"]
                        ]
                    ]
                ],
                "recommendation": ["type": "string"],
                "tonightAction": ["type": "string"],
                "tomorrowVerification": [
                    "type": "array",
                    "items": [
                        "type": "object",
                        "additionalProperties": false,
                        "required": ["id", "metric", "expectedDirection", "reason"],
                        "properties": [
                            "id": ["type": "string", "format": "uuid"],
                            "metric": ["type": "string"],
                            "expectedDirection": ["type": "string"],
                            "reason": ["type": "string"]
                        ]
                    ]
                ],
                "followupQuestion": ["anyOf": [["type": "string"], ["type": "null"]]],
                "safetyNote": ["anyOf": [["type": "string"], ["type": "null"]]],
                "createdAt": ["type": "string", "format": "date-time"]
            ]
        ]
    }
}

private extension ConfidenceLevel {
    static var allCasesRawValues: [String] {
        [ConfidenceLevel.high.rawValue, ConfidenceLevel.medium.rawValue, ConfidenceLevel.low.rawValue]
    }
}

extension ISO8601DateFormatter {
    static func oheasString(from date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }
}
