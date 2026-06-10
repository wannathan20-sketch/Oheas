//
//  CodableFileStore.swift
//  OHeas
//
//  Generic JSON file-based Codable storage.
//  基于 JSON 文件的通用 Codable 存储。
//


import Foundation

public struct CodableFileStore<Element: Codable & Sendable>: Sendable {
    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(
        fileURL: URL,
        encoder: JSONEncoder = .oheasPretty,
        decoder: JSONDecoder = .oheas
    ) {
        self.fileURL = fileURL
        self.encoder = encoder
        self.decoder = decoder
    }

    public func load() throws -> [Element] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }
        let data = try Data(contentsOf: fileURL)
        return try decoder.decode([Element].self, from: data)
    }

    public func save(_ values: [Element]) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let data = try encoder.encode(values)
        try data.write(to: fileURL, options: [.atomic])
    }

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

public extension JSONDecoder {
    static var oheas: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
