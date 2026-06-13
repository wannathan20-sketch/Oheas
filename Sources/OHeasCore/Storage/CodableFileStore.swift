//
//  CodableFileStore.swift
//  OHeas
//
//  Generic JSON file-based Codable storage with optional schema versioning.
//  基于 JSON 文件的通用 Codable 存储，支持 schema 版本化。
//

import Foundation

// MARK: - Versioned wrapper

/// Wraps an array of items with a schema version for forward/backward compatibility.
struct VersionedContainer<Item: Codable & Sendable>: Codable, Sendable {
    let schemaVersion: Int
    let items: [Item]
}

// MARK: - CodableFileStore

public struct CodableFileStore<Element: Codable & Sendable>: Sendable {
    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    /// Current schema version. When set, data is wrapped in a versioned container.
    /// When the stored version doesn't match, migration is attempted.
    private let schemaVersion: Int?
    /// Migration function: (oldVersion, oldData) → migrated data.
    /// Return nil to skip migration (data will be treated as empty).
    private let migrator: (@Sendable (Int, Data) -> [Element]?)?

    public init(
        fileURL: URL,
        encoder: JSONEncoder = .oheasPretty,
        decoder: JSONDecoder = .oheas,
        schemaVersion: Int? = nil,
        migrator: (@Sendable (Int, Data) -> [Element]?)? = nil
    ) {
        self.fileURL = fileURL
        self.encoder = encoder
        self.decoder = decoder
        self.schemaVersion = schemaVersion
        self.migrator = migrator
    }

    // MARK: - Load

    public func load() throws -> [Element] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }
        let data = try Data(contentsOf: fileURL)

        // If schema versioning is enabled, read through the container.
        if let currentVersion = schemaVersion {
            return try loadVersioned(data: data, currentVersion: currentVersion)
        }

        return try decoder.decode([Element].self, from: data)
    }

    private func loadVersioned(data: Data, currentVersion: Int) throws -> [Element] {
        // Try reading as versioned container first.
        if let container = try? decoder.decode(VersionedContainer<Element>.self, from: data) {
            if container.schemaVersion == currentVersion {
                return container.items
            }
            // Version mismatch — try migration.
            if let migrator = migrator,
               let migrated = migrator(container.schemaVersion, data) {
                // Save migrated data with new version.
                let newContainer = VersionedContainer(schemaVersion: currentVersion, items: migrated)
                let encoded = try encoder.encode(newContainer)
                try encoded.write(to: fileURL, options: [.atomic])
                return migrated
            }
            // No migrator or migration failed — return empty, file will be overwritten on next save.
            print("[CodableFileStore] Schema version mismatch for \(fileURL.lastPathComponent): stored=\(container.schemaVersion) current=\(currentVersion). Data reset.")
            return []
        }

        // Legacy data (no version wrapper). Treat as version 0.
        if let legacyItems = try? decoder.decode([Element].self, from: data) {
            if let migrator = migrator,
               let migrated = migrator(0, data) {
                let newContainer = VersionedContainer(schemaVersion: currentVersion, items: migrated)
                let encoded = try encoder.encode(newContainer)
                try encoded.write(to: fileURL, options: [.atomic])
                return migrated
            }
            // No migrator — save as-is with current version.
            let newContainer = VersionedContainer(schemaVersion: currentVersion, items: legacyItems)
            let encoded = try encoder.encode(newContainer)
            try encoded.write(to: fileURL, options: [.atomic])
            return legacyItems
        }

        return []
    }

    // MARK: - Save

    public func save(_ values: [Element]) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let data: Data
        if let version = schemaVersion {
            let container = VersionedContainer(schemaVersion: version, items: values)
            data = try encoder.encode(container)
        } else {
            data = try encoder.encode(values)
        }

        try data.write(to: fileURL, options: [.atomic])
    }

    // MARK: - Upsert

    public func upsert(_ value: Element, where shouldReplace: (Element) -> Bool) throws {
        var values = try load()
        if let index = values.firstIndex(where: shouldReplace) {
            values[index] = value
        } else {
            values.append(value)
        }
        try save(values)
    }
}

// MARK: - JSONDecoder + JSONEncoder

public extension JSONDecoder {
    static var oheas: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

