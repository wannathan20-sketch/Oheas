//
//  SyncEngine.swift
//  OHeas
//
//  Syncs local data to backend with conflict resolution and privacy guards.
//  将本地数据同步到后端，带冲突解决和隐私保护。
//


import Foundation

public enum SyncEntityType: String, Codable, CaseIterable, Sendable {
    case userGoal = "user_goal"
    case dailyHealthMetrics = "daily_health_metrics"
    case dataQualityReport = "data_quality_report"
    case coachRecommendation = "coach_recommendation"
    case dailyFeedback = "daily_feedback"
    case verificationReport = "verification_report"
    case userMemory = "user_memory"
    case personalExperiment = "personal_experiment"
    case weeklyPlan = "weekly_plan"
    case weeklyReview = "weekly_review"
    case privacySettings = "privacy_settings"
    case effectivenessReport = "effectiveness_report"
    case safetyAssessment = "safety_assessment"
    case betaAnalyticsEvent = "beta_analytics_event"
}

public enum SyncOperation: String, Codable, CaseIterable, Sendable {
    case upsert
    case delete
}

public enum SyncRecordStatus: String, Codable, CaseIterable, Sendable {
    case pending
    case syncing
    case synced
    case failed
}

public enum SyncMode: String, Codable, CaseIterable, Sendable {
    case localOnly
    case cloudEnabled
    case paused
}

public struct SyncRecord: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var userId: UUID?
    public var entityType: SyncEntityType
    public var entityId: String
    public var operation: SyncOperation
    public var payload: String
    public var status: SyncRecordStatus
    public var retryCount: Int
    public var lastError: String?
    public var createdAt: Date
    public var updatedAt: Date
    public var deletedAt: Date?

    public init(
        id: UUID = UUID(),
        userId: UUID? = nil,
        entityType: SyncEntityType,
        entityId: String,
        operation: SyncOperation,
        payload: String,
        status: SyncRecordStatus = .pending,
        retryCount: Int = 0,
        lastError: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.entityType = entityType
        self.entityId = entityId
        self.operation = operation
        self.payload = payload
        self.status = status
        self.retryCount = retryCount
        self.lastError = lastError
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }

    public static func make<T: Encodable>(
        entityType: SyncEntityType,
        entityId: String,
        operation: SyncOperation,
        payload: T,
        encoder: JSONEncoder = .oheasPretty
    ) throws -> SyncRecord {
        let data = try encoder.encode(payload)
        let json = String(data: data, encoding: .utf8) ?? "{}"
        return SyncRecord(entityType: entityType, entityId: entityId, operation: operation, payload: json)
    }

    public var containsRawHealthSampleKeys: Bool {
        let lower = payload.lowercased()
        return ["rawhealthsamples", "sleepsegments", "hrvsamples", "restingheartratesamples"].contains { lower.contains($0) }
    }

    public func withUserId(_ userId: UUID) -> SyncRecord {
        var copy = self
        copy.userId = userId
        return copy
    }
}

public struct SyncState: Codable, Equatable, Sendable {
    public var lastSyncedAt: Date?
    public var mode: SyncMode
    public var pendingCount: Int
    public var lastError: String?

    public init(lastSyncedAt: Date? = nil, mode: SyncMode = .localOnly, pendingCount: Int = 0, lastError: String? = nil) {
        self.lastSyncedAt = lastSyncedAt
        self.mode = mode
        self.pendingCount = pendingCount
        self.lastError = lastError
    }
}

public struct SyncEngine: Sendable {
    private let queueStore: CodableFileStore<SyncRecord>
    private let stateStore: SingleValueStore<SyncState>
    private let apiClient: BackendAPIClientProtocol
    private let consentManager: ConsentManager?

    public init(
        queueURL: URL,
        stateURL: URL,
        apiClient: BackendAPIClientProtocol = LocalBackendAPIClient(),
        consentManager: ConsentManager? = nil
    ) {
        self.queueStore = CodableFileStore(fileURL: queueURL)
        self.stateStore = SingleValueStore(fileURL: stateURL, defaultValue: SyncState())
        self.apiClient = apiClient
        self.consentManager = consentManager
    }

    public func loadState() -> SyncState {
        var state = (try? stateStore.load()) ?? SyncState()
        state.pendingCount = ((try? queueStore.load()) ?? []).filter { $0.status == .pending || $0.status == .failed }.count
        if consentManager?.hasConsent(.cloudSync) != true, state.mode != .localOnly {
            state.mode = .localOnly
        }
        return state
    }

    public func saveState(_ state: SyncState) throws {
        try stateStore.save(state)
    }

    public func pause() throws {
        var state = loadState()
        state.mode = .paused
        try saveState(state)
    }

    public func resumeCloudSync() throws {
        var state = loadState()
        state.mode = consentManager?.hasConsent(.cloudSync) == true ? .cloudEnabled : .localOnly
        try saveState(state)
    }

    public func enqueue<T: Encodable>(_ value: T, entityType: SyncEntityType, entityId: String, operation: SyncOperation = .upsert) throws {
        let record = try SyncRecord.make(entityType: entityType, entityId: entityId, operation: operation, payload: value)
        guard !record.containsRawHealthSampleKeys else { throw BackendClientError.rawHealthSamplesRejected }
        var queue = try queueStore.load()
        queue.append(record)
        try queueStore.save(queue)
        var state = loadState()
        state.pendingCount = queue.filter { $0.status == .pending || $0.status == .failed }.count
        try saveState(state)
    }

    public func syncNow(userId: UUID) async -> SyncState {
        var state = loadState()
        guard state.mode == .cloudEnabled, consentManager?.hasConsent(.cloudSync) == true else {
            state.mode = .localOnly
            state.pendingCount = ((try? queueStore.load()) ?? []).filter { $0.status == .pending || $0.status == .failed }.count
            try? saveState(state)
            return state
        }

        var queue = (try? queueStore.load()) ?? []
        for index in queue.indices where queue[index].status == .pending || queue[index].status == .failed {
            queue[index].status = .syncing
            queue[index].updatedAt = Date()
            do {
                try await upload(queue[index], userId: userId)
                queue[index].status = .synced
                queue[index].lastError = nil
            } catch {
                queue[index].status = .failed
                queue[index].retryCount += 1
                queue[index].lastError = error.localizedDescription
                state.lastError = error.localizedDescription
            }
            queue[index].updatedAt = Date()
        }
        try? queueStore.save(queue)
        state.lastSyncedAt = Date()
        state.pendingCount = queue.filter { $0.status == .pending || $0.status == .failed }.count
        try? saveState(state)
        return state
    }

    public func pendingRecords() -> [SyncRecord] {
        ((try? queueStore.load()) ?? []).filter { $0.status == .pending || $0.status == .failed }
    }

    public func resolveConflict(local: SyncRecord, remote: SyncRecord) -> SyncRecord {
        if local.entityType == .privacySettings {
            return local
        }
        if let localDeleted = local.deletedAt, let remoteDeleted = remote.deletedAt {
            return localDeleted >= remoteDeleted ? local : remote
        }
        if local.deletedAt != nil { return local }
        if remote.deletedAt != nil { return remote }
        return local.updatedAt >= remote.updatedAt ? local : remote
    }

    private func upload(_ record: SyncRecord, userId: UUID) async throws {
        guard !record.containsRawHealthSampleKeys else { throw BackendClientError.rawHealthSamplesRejected }
        switch record.operation {
        case .delete:
            try await apiClient.markDeleted(entityType: record.entityType, id: record.entityId, userId: userId)
        case .upsert:
            try await apiClient.uploadSyncRecord(record, userId: userId)
        }
    }
}

public struct SingleValueStore<Value: Codable & Sendable>: Sendable {
    private let fileURL: URL
    private let defaultValue: Value
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(fileURL: URL, defaultValue: Value, encoder: JSONEncoder = .oheasPretty, decoder: JSONDecoder = .oheas) {
        self.fileURL = fileURL
        self.defaultValue = defaultValue
        self.encoder = encoder
        self.decoder = decoder
    }

    public func load() throws -> Value {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return defaultValue }
        return try decoder.decode(Value.self, from: Data(contentsOf: fileURL))
    }

    public func save(_ value: Value) throws {
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try encoder.encode(value).write(to: fileURL, options: [.atomic])
    }
}
