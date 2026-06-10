//
//  HealthDataProvider.swift
//  OHeas
//
//  Protocol and factory for HealthKit vs mock data sources.
//  HealthKit 与模拟数据源的协议和工厂。
//


import Foundation

public protocol HealthDataProvider: Sendable {
    func fetchRawDailyData(days: Int) async throws -> [RawDailyHealthData]
}

public enum HealthDataProviderError: Error, LocalizedError, Sendable {
    case healthDataUnavailable
    case authorizationDenied
    case queryFailed(String)

    public var errorDescription: String? {
        switch self {
        case .healthDataUnavailable:
            "Health data is unavailable on this device."
        case .authorizationDenied:
            "HealthKit authorization was denied or not granted."
        case .queryFailed(let message):
            "HealthKit query failed: \(message)"
        }
    }
}
