//
//  RAGService.swift
//  OHeas
//
//  Semantic search over health memory using backend pgvector.
//  对健康记忆做语义检索，支持后端 pgvector 搜索 + 本地文本 fallback。
//

import Foundation

// MARK: - Models

public struct RAGSearchResult: Codable, Sendable, Identifiable {
    public let id: UUID
    public let sourceType: String
    public let sourceId: String
    public let content: String
    public let similarity: Double

    public var sourceLabel: String {
        switch sourceType {
        case "pattern":      return "发现的模式"
        case "intervention": return "有效干预"
        case "feedback":     return "历史反馈"
        case "experiment":   return "实验记录"
        case "recommendation": return "过往建议"
        case "review":       return "周复盘"
        default:             return sourceType
        }
    }
}

public struct RAGSearchResponse: Codable, Sendable {
    public let results: [RAGSearchResult]
    public let queryEmbeddingGenerated: Bool
}

public struct MemoryIndexItem: Codable, Sendable {
    public let sourceType: String
    public let sourceId: String
    public let content: String

    public init(sourceType: String, sourceId: String, content: String) {
        self.sourceType = sourceType
        self.sourceId = sourceId
        self.content = content
    }
}

// MARK: - RAG Client Protocol

public protocol RAGClientProtocol: Sendable {
    func search(query: String, topK: Int, sourceTypes: [String]?) async throws -> RAGSearchResponse
    func index(items: [MemoryIndexItem]) async throws
}

// MARK: - Local Fallback

public actor LocalRAGClient: RAGClientProtocol {
    /// In-memory store of indexed items for local text search.
    private var indexedItems: [MemoryIndexItem] = []

    public init() {}

    public func search(query: String, topK: Int, sourceTypes: [String]?) async throws -> RAGSearchResponse {
        var filtered = indexedItems
        if let types = sourceTypes {
            filtered = filtered.filter { types.contains($0.sourceType) }
        }

        // Simple token-based relevance scoring
        let queryTokens = query.lowercased().split(separator: " ").map(String.init)
        guard !queryTokens.isEmpty else {
            return RAGSearchResponse(results: [], queryEmbeddingGenerated: false)
        }

        var scored: [(item: MemoryIndexItem, score: Double)] = []
        for item in filtered {
            let lower = item.content.lowercased()
            var score = 0.0
            for token in queryTokens {
                if lower.contains(token) { score += 1.0 }
            }
            if score > 0 {
                scored.append((item, score / Double(queryTokens.count)))
            }
        }

        scored.sort(by: { $0.score > $1.score })
        let top = scored.prefix(topK)

        let results: [RAGSearchResult] = top.map { entry in
            RAGSearchResult(
                id: UUID(),
                sourceType: entry.item.sourceType,
                sourceId: entry.item.sourceId,
                content: entry.item.content,
                similarity: entry.score
            )
        }
        return RAGSearchResponse(results: results, queryEmbeddingGenerated: false)
    }

    public func index(items: [MemoryIndexItem]) async throws {
        for item in items {
            indexedItems.removeAll { $0.sourceType == item.sourceType && $0.sourceId == item.sourceId }
            indexedItems.append(item)
        }
        if indexedItems.count > 200 {
            indexedItems = Array(indexedItems.suffix(200))
        }
    }
}

// MARK: - HTTP Backend RAG Client

public final class HTTPRAGClient: RAGClientProtocol, @unchecked Sendable {
    private let baseURL: URL
    private let bearerToken: String
    private let session: URLSession

    public init(baseURL: URL, bearerToken: String, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.bearerToken = bearerToken
        self.session = session
    }

    public func search(query: String, topK: Int, sourceTypes: [String]?) async throws -> RAGSearchResponse {
        let url = baseURL.appendingPathComponent("v1/rag/search")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")

        var body: [String: Any] = ["query": query, "top_k": topK]
        if let types = sourceTypes { body["source_types"] = types }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(RAGSearchResponse.self, from: data)
    }

    public func index(items: [MemoryIndexItem]) async throws {
        let url = baseURL.appendingPathComponent("v1/rag/index")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")

        let dictItems = items.map { ["source_type": $0.sourceType, "source_id": $0.sourceId, "content": $0.content] }
        let body = ["items": dictItems]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
}

// MARK: - RAG Service (orchestrator)

public final class RAGService: @unchecked Sendable {
    private var backendClient: (any RAGClientProtocol)?
    private var localClient: LocalRAGClient

    public init(backendClient: (any RAGClientProtocol)? = nil) {
        self.backendClient = backendClient
        self.localClient = LocalRAGClient()
    }

    /// Update backend configuration when user signs in.
    public func configureBackend(baseURL: URL?, bearerToken: String?) {
        if let url = baseURL, let token = bearerToken {
            backendClient = HTTPRAGClient(baseURL: url, bearerToken: token)
        } else {
            backendClient = nil
        }
    }

    /// Search for relevant memories.
    /// Tries backend pgvector first, falls back to local text search.
    public func search(query: String, topK: Int = 3, sourceTypes: [String]? = nil) async -> [RAGSearchResult] {
        // Try backend
        if let client = backendClient {
            do {
                let response = try await client.search(query: query, topK: topK, sourceTypes: sourceTypes)
                if response.queryEmbeddingGenerated, !response.results.isEmpty {
                    return response.results
                }
                // If backend returned no embedding results, also try local
                let localResponse = try await localClient.search(query: query, topK: topK, sourceTypes: sourceTypes)
                return mergeResults(backend: response.results, local: localResponse.results, topK: topK)
            } catch {
                // Backend unavailable — fall through to local
            }
        }

        // Local fallback
        do {
            let response = try await localClient.search(query: query, topK: topK, sourceTypes: sourceTypes)
            return response.results
        } catch {
            return []
        }
    }

    /// Index health memory items for future search.
    public func index(items: [MemoryIndexItem]) async {
        // Always index locally
        do {
            try await localClient.index(items: items)
        } catch {}

        // Try backend indexing
        if let client = backendClient {
            do {
                try await client.index(items: items)
            } catch {
                // Silently fail — local index is sufficient
            }
        }
    }

    /// Clear local index (e.g., on data reset).
    public func resetLocal() {
        localClient = LocalRAGClient()
    }

    // MARK: - Helpers

    private func mergeResults(backend: [RAGSearchResult], local: [RAGSearchResult], topK: Int) -> [RAGSearchResult] {
        var seen = Set<String>()
        var merged: [RAGSearchResult] = []
        for r in backend { merged.append(r); seen.insert(r.id.uuidString) }
        for r in local where !seen.contains(r.id.uuidString) {
            merged.append(r)
        }
        return Array(merged.prefix(topK))
    }
}
