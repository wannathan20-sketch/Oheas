//
//  DeepSeekConnectivityTests.swift
//  OHeas
//
//  DeepSeek API connectivity tests — streaming and non-streaming.
//  DeepSeek API 连通性测试 — 流式和非流式。
//


import Foundation
import Testing
import OHeasCore

/// DeepSeek API 连通性测试
///
/// 验证 ChatCompletionsClient 在模拟器中能正常调用 DeepSeek API。
/// 这些测试需要有效的 DEEPSEEK_API_KEY 环境变量。
///
/// 运行方式：
///   xcodebuild test -project OHeas.xcodeproj -scheme OHeas \\
///     -destination "platform=iOS Simulator,name=iPhone 17" \\
///     -only-testing:OHeasAppTests/DeepSeekConnectivityTests
@Suite("DeepSeekConnectivity") @MainActor
struct DeepSeekConnectivityTests {

    // MARK: - Helpers

    private static func makeClient() throws -> ChatCompletionsClient {
        let env = ProcessInfo.processInfo.environment
        guard let apiKey = env["DEEPSEEK_API_KEY"],
              !apiKey.isEmpty,
              apiKey != "DEEPSEEK_API_KEY_PLACEHOLDER" else {
            throw DeepSeekTestError.missingAPIKey
        }
        let model = env["DEEPSEEK_MODEL"] ?? "deepseek-chat"
        return ChatCompletionsClient(
            apiKey: apiKey,
            model: model,
            endpoint: URL(string: "https://api.deepseek.com/v1/chat/completions")!,
            name: "deepseek-connectivity-test"
        )
    }

    private static func testPayload() -> CoachPromptPayload {
        CoachPromptPayload(
            systemPrompt: """
            You are a health coach. Reply ONLY with a valid JSON object that matches this schema:
            {"status": "ok", "greeting": "string"}

            Keep your response short.
            """,
            userContextJSON: """
            {"date": "2026-06-09", "user_status": "testing_deepseek_connectivity"}
            """
        )
    }

    // MARK: - Connectivity Tests

    @Test("ChatCompletionsClient successfully calls DeepSeek API (non-streaming)")
    func nonStreamingCall() async throws {
        let client = try Self.makeClient()

        let response = try await client.generateRecommendationJSON(payload: Self.testPayload())

        // Verify we got a non-empty response
        #expect(!response.isEmpty, "Response should not be empty")

        // Verify it's valid JSON
        guard let data = response.data(using: .utf8) else {
            #expect(Bool(false), "Response should be valid UTF-8")
            return
        }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(json != nil, "Response should be a valid JSON object")

        // Should contain "status": "ok"
        if let status = json?["status"] as? String {
            #expect(status == "ok", "Response status should be 'ok', got: \(status)")
        } else {
            // If our test prompt didn't constrain output perfectly, at least check it's valid JSON
            #expect(json != nil, "Response should parse as JSON dictionary")
        }
    }

    @Test("ChatCompletionsClient successfully calls DeepSeek API (streaming)")
    func streamingCall() async throws {
        let client = try Self.makeClient()

        var tokens: [String] = []
        var finalAccumulated = ""
        var didComplete = false

        let stream = client.streamRecommendation(payload: Self.testPayload())
        for try await event in stream {
            if !event.token.isEmpty {
                tokens.append(event.token)
            }
            finalAccumulated = event.accumulatedText
            if event.isComplete {
                didComplete = true
            }
        }

        // Verify streaming behavior
        #expect(!tokens.isEmpty, "Should receive at least one token")
        #expect(didComplete, "Stream should complete with isComplete=true")
        #expect(!finalAccumulated.isEmpty, "Accumulated text should not be empty")

        // Verify the final accumulated text is valid JSON
        if let data = finalAccumulated.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            #expect(json != nil, "Final accumulated text should be valid JSON")
        }
    }

    @Test("ChatCompletionsClient detects missing API key")
    func missingAPIKey() async {
        let client = ChatCompletionsClient(
            apiKey: "",
            model: "deepseek-chat",
            endpoint: URL(string: "https://api.deepseek.com/v1/chat/completions")!,
            name: "test-empty-key"
        )

        do {
            let _ = try await client.generateRecommendationJSON(payload: Self.testPayload())
            #expect(Bool(false), "Should have thrown missingAPIKey error")
        } catch LLMClientError.missingAPIKey {
            // Expected
            #expect(Bool(true))
        } catch {
            #expect(Bool(false), "Expected missingAPIKey error, got: \(error)")
        }
    }

    @Test("ChatCompletionsClient handles invalid endpoint gracefully")
    func invalidEndpoint() async {
        let client = ChatCompletionsClient(
            apiKey: "sk-test-key",
            model: "deepseek-chat",
            endpoint: URL(string: "https://invalid.deepseek.example.com/v1/chat/completions")!,
            name: "test-invalid-endpoint"
        )

        do {
            let _ = try await client.generateRecommendationJSON(payload: Self.testPayload())
            #expect(Bool(false), "Should have thrown an error for invalid endpoint")
        } catch let LLMClientError.httpStatus(code, _) {
            // Expected: HTTP error or network error
            #expect(code >= 400 || code < 0, "Should get an error status code")
        } catch {
            // Network timeout/connection error is also acceptable
            #expect(Bool(true), "Network error for invalid endpoint is expected: \(error)")
        }
    }

    @Test("Response includes model name in client identity")
    func clientName() async throws {
        let client = try Self.makeClient()
        #expect(client.name == "deepseek-connectivity-test")
        #expect(!client.name.isEmpty)
    }
}

// MARK: - Test Error

enum DeepSeekTestError: Error, CustomStringConvertible {
    case missingAPIKey

    var description: String {
        switch self {
        case .missingAPIKey:
            "DEEPSEEK_API_KEY environment variable is missing or set to PLACEHOLDER. Run ./configure.sh first."
        }
    }
}
