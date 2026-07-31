//
//  HealthKitManager+SampleExtraction.swift
//  HealthKitService
//
//  Created by 김혜지 on 7/30/26.
//

import Foundation
import HealthKit
import Models

extension HealthKitManager {
    /// 워크아웃 구간의 원시 시계열 8종을 병렬로 조회한다.
    func fetchSampleSet(for workout: HKWorkout) async -> WorkoutSampleSet {
        async let heartRate = fetchMetricSamples(
            for: workout, type: HKQuantityTypeCatalog.heartRate, unit: HKUnitCatalog.bpm
        )
        async let pace = fetchPaceSamples(for: workout)
        async let cadence = fetchCadenceSamples(for: workout)
        async let power = fetchMetricSamples(
            for: workout, type: HKQuantityTypeCatalog.runningPower, unit: HKUnitCatalog.watt
        )
        async let verticalOscillation = fetchMetricSamples(
            for: workout, type: HKQuantityTypeCatalog.runningVerticalOscillation, unit: HKUnitCatalog.centimeter
        )
        async let groundContactTime = fetchMetricSamples(
            for: workout, type: HKQuantityTypeCatalog.runningGroundContactTime, unit: HKUnitCatalog.millisecond
        )
        async let stepLength = fetchMetricSamples(
            for: workout, type: HKQuantityTypeCatalog.walkingStepLength, unit: HKUnitCatalog.meter
        )
        async let strideLength = fetchMetricSamples(
            for: workout, type: HKQuantityTypeCatalog.runningStrideLength, unit: HKUnitCatalog.meter
        )

        return await WorkoutSampleSet(
            heartRate: heartRate,
            paceSecondsPerKm: pace,
            cadence: cadence,
            power: power,
            verticalOscillation: verticalOscillation,
            groundContactTime: groundContactTime,
            stepLength: stepLength,
            strideLength: strideLength
        )
    }

    /// 워크아웃 구간의 `type` 샘플을 `unit`으로 변환해 `MetricSample` 배열로 조회한다. (쿼리 1회)
    func fetchMetricSamples(
        for workout: HKWorkout,
        type: HKQuantityType,
        unit: HKUnit
    ) async -> [MetricSample] {
        let samples = await fetchQuantitySamples(for: workout, type: type)

        return samples.map { sample in
            MetricSample(
                offsetSec: sample.startDate.timeIntervalSince(workout.startDate),
                value: sample.quantity.doubleValue(for: unit)
            )
        }
    }

    /// runningSpeed(m/s) 시계열을 `paceSecondsPerKm = 1000 / speed`로 변환한다. speed가 0 이하이면 제외한다.
    func fetchPaceSamples(for workout: HKWorkout) async -> [MetricSample] {
        let speedSamples = await fetchMetricSamples(
            for: workout,
            type: HKQuantityTypeCatalog.runningSpeed,
            unit: HKUnitCatalog.meterPerSecond
        )

        return speedSamples.compactMap { sample in
            guard sample.value > 0 else { return nil }

            return MetricSample(offsetSec: sample.offsetSec, value: 1000 / sample.value)
        }
    }

    /// stepCount 샘플을 각 샘플 구간(spm)으로 환산해 케이던스 시계열을 만든다.
    func fetchCadenceSamples(for workout: HKWorkout) async -> [MetricSample] {
        let stepSamples = await fetchQuantitySamples(for: workout, type: HKQuantityTypeCatalog.stepCount)

        return stepSamples.compactMap { sample -> MetricSample? in
            let durationMinutes = sample.endDate.timeIntervalSince(sample.startDate) / 60
            guard durationMinutes > 0 else { return nil }

            let steps = sample.quantity.doubleValue(for: .count())
            return MetricSample(
                offsetSec: sample.startDate.timeIntervalSince(workout.startDate),
                value: steps / durationMinutes
            )
        }
    }

    /// 워크아웃 구간의 `HKQuantitySample`을 시작 시각 오름차순으로 조회하는 공통 헬퍼.
    func fetchQuantitySamples(
        for workout: HKWorkout,
        type: HKQuantityType
    ) async -> [HKQuantitySample] {
        let predicate = HKQuery.predicateForSamples(
            withStart: workout.startDate,
            end: workout.endDate,
            options: .strictStartDate
        )

        return await withCheckedContinuation { (continuation: CheckedContinuation<[HKQuantitySample], Never>) in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, results, error in
                if error != nil {
                    continuation.resume(returning: [])
                    return
                }
                continuation.resume(returning: results as? [HKQuantitySample] ?? [])
            }
            healthStore.execute(query)
        }
    }
}
