//
//  HealthKitReader.swift
//  OHeas
//
//  Reads sleep, HRV, RHR, steps, energy, exercise, workouts from HealthKit.
//  从 HealthKit 读取睡眠、HRV、静息心率、步数、能量、运动和训练。
//


import Foundation

#if canImport(HealthKit) && os(iOS)
import HealthKit

public final class HealthKitReader: HealthDataProvider, @unchecked Sendable {
    private let healthStore: HKHealthStore
    private let calendar: Calendar

    public init(healthStore: HKHealthStore = HKHealthStore(), calendar: Calendar = .current) {
        self.healthStore = healthStore
        self.calendar = calendar
    }

    public func fetchRawDailyData(days: Int) async throws -> [RawDailyHealthData] {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthDataProviderError.healthDataUnavailable
        }

        // 授权失败会向上抛出，由 App 层自动切换到 mock provider，保证 demo 可运行。
        try await requestAuthorization()

        let today = calendar.startOfDay(for: Date())
        var output: [RawDailyHealthData] = []
        for offsetFromStart in 0..<days {
            let daysAgo = days - 1 - offsetFromStart
            guard
                let start = calendar.date(byAdding: .day, value: -daysAgo, to: today),
                let end = calendar.date(byAdding: .day, value: 1, to: start)
            else {
                continue
            }

            async let sleep = sleepSegments(start: start, end: end)
            async let hrv = averageQuantitySamples(.heartRateVariabilitySDNN, unit: .secondUnit(with: .milli), start: start, end: end)
            async let resting = averageQuantitySamples(.restingHeartRate, unit: HKUnit.count().unitDivided(by: .minute()), start: start, end: end)
            async let steps = cumulativeQuantity(.stepCount, unit: .count(), start: start, end: end)
            async let energy = cumulativeQuantity(.activeEnergyBurned, unit: .kilocalorie(), start: start, end: end)
            async let exercise = cumulativeQuantity(.appleExerciseTime, unit: .minute(), start: start, end: end)
            async let workouts = workouts(start: start, end: end)

            // 每天独立查询，便于后续按天缓存，也方便区分某一天的缺失状态。
            output.append(
                RawDailyHealthData(
                    date: start,
                    sleepSegments: try await sleep,
                    hrvSamples: try await hrv,
                    restingHeartRateSamples: try await resting,
                    steps: try await steps,
                    activeEnergyKcal: try await energy,
                    exerciseMinutes: try await exercise,
                    workouts: try await workouts,
                    workoutsQueried: true
                )
            )
        }
        return output
    }

    private func requestAuthorization() async throws {
        var types = Set<HKObjectType>()
        types.insert(HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!)
        types.insert(HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!)
        types.insert(HKObjectType.quantityType(forIdentifier: .restingHeartRate)!)
        types.insert(HKObjectType.quantityType(forIdentifier: .stepCount)!)
        types.insert(HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!)
        types.insert(HKObjectType.quantityType(forIdentifier: .appleExerciseTime)!)
        types.insert(HKObjectType.workoutType())

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            healthStore.requestAuthorization(toShare: [], read: types) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: HealthDataProviderError.authorizationDenied)
                }
            }
        }
    }

    private func sleepSegments(start: Date, end: Date) async throws -> [SleepSegment] {
        guard let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return [] }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictEndDate)

        let samples: [HKCategorySample] = try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: samples as? [HKCategorySample] ?? [])
                }
            }
            healthStore.execute(query)
        }

        return samples.compactMap { sample in
            guard let stage = SleepStage(healthKitValue: sample.value) else { return nil }
            let clippedStart = max(sample.startDate, start)
            let clippedEnd = min(sample.endDate, end)
            guard clippedEnd > clippedStart else { return nil }
            return SleepSegment(startDate: clippedStart, endDate: clippedEnd, stage: stage)
        }
    }

    private func averageQuantitySamples(
        _ identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        start: Date,
        end: Date
    ) async throws -> [Double] {
        guard let type = HKObjectType.quantityType(forIdentifier: identifier) else { return [] }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictEndDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    let values = (samples as? [HKQuantitySample] ?? []).map { $0.quantity.doubleValue(for: unit) }
                    continuation.resume(returning: values)
                }
            }
            healthStore.execute(query)
        }
    }

    private func cumulativeQuantity(
        _ identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        start: Date,
        end: Date
    ) async throws -> Double? {
        guard let type = HKObjectType.quantityType(forIdentifier: identifier) else { return nil }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, statistics, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: statistics?.sumQuantity()?.doubleValue(for: unit))
                }
            }
            healthStore.execute(query)
        }
    }

    private func workouts(start: Date, end: Date) async throws -> [WorkoutSummary] {
        let type = HKObjectType.workoutType()
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)

        let samples: [HKWorkout] = try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: samples as? [HKWorkout] ?? [])
                }
            }
            healthStore.execute(query)
        }

        return samples.map { workout in
            WorkoutSummary(
                type: workout.workoutActivityType.oheasName,
                startDate: workout.startDate,
                durationMinutes: workout.duration / 60.0,
                activeEnergyKcal: workout.totalEnergyBurned?.doubleValue(for: .kilocalorie())
            )
        }
    }
}

private extension SleepStage {
    init?(healthKitValue: Int) {
        if #available(iOS 16.0, *) {
            switch healthKitValue {
            case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
                self = .asleepCore
            case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                self = .asleepDeep
            case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                self = .asleepREM
            case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue:
                self = .asleepUnspecified
            default:
                return nil
            }
        } else {
            guard healthKitValue == HKCategoryValueSleepAnalysis.asleep.rawValue else { return nil }
            self = .asleepUnspecified
        }
    }
}

private extension HKWorkoutActivityType {
    var oheasName: String {
        switch self {
        case .running: "Running"
        case .walking: "Walking"
        case .cycling: "Cycling"
        case .traditionalStrengthTraining: "Strength Training"
        case .functionalStrengthTraining: "Functional Strength Training"
        case .yoga: "Yoga"
        case .swimming: "Swimming"
        case .hiking: "Hiking"
        case .highIntensityIntervalTraining: "HIIT"
        default: "Workout"
        }
    }
}
#else
public struct HealthKitReader: HealthDataProvider {
    public init() {}

    public func fetchRawDailyData(days: Int) async throws -> [RawDailyHealthData] {
        throw HealthDataProviderError.healthDataUnavailable
    }
}
#endif
