//
//  HealthKitManager+WorkoutAssembly.swift
//  HealthKitService
//
//  Created by 김혜지 on 7/30/26.
//

import Foundation
import HealthKit
import Models

extension HealthKitManager {
    /// 워크아웃 하나에 대한 전체 상세 데이터를 추출해 `HealthKitWorkout`으로 구성한다.
    ///
    /// 거리가 없는 워크아웃(트레드밀 등)도 버리지 않는다. 페이스만 nil이 되고 나머지 지표는 그대로 기록한다.
    /// 평균 스칼라는 워크아웃 통계 쿼리를 우선 사용하고 통계가 없으면 시계열 산술평균으로 폴백한다.
    func makeWorkout(from workout: HKWorkout) async -> HealthKitWorkout {
        // 워크아웃당 십여 회의 쿼리가 필요하므로 서로 독립적인 조회는 병렬로 수행한다.
        async let sampleSetTask = fetchSampleSet(for: workout)
        async let routeTask = fetchRouteExtractionResult(for: workout)
        async let restingHeartRateTask = fetchAverageRestingHeartRate(for: workout)
        async let heartRateRecoveryTask = fetchHeartRateRecoveryOneMinute(for: workout)
        async let basalEnergyTask = fetchBasalEnergyBurned(for: workout)
        async let zoneSummariesTask = fetchZoneSummaries(for: workout)

        let samples = await sampleSetTask
        let routeExtraction = await routeTask
        let restingHeartRate = await restingHeartRateTask ?? 0
        let heartRateRecoveryOneMinute = await heartRateRecoveryTask ?? 0
        let basalEnergyBurned = await basalEnergyTask
        let zoneSummaries = await zoneSummariesTask

        // 랩은 워크아웃 객체가 이미 보유한 활동 정보에서 도출하므로 추가 쿼리가 없다.
        let laps = makeLaps(from: workout)

        let distance = workout.statistics(for: HKQuantityTypeCatalog.distanceWalkingRunning)?
            .sumQuantity()?
            .doubleValue(for: HKUnitCatalog.kilometer) ?? 0
        let averagePaceSecondsPerKm = PaceMapper.secondsPerKm(
            fromDurationSec: workout.duration,
            distanceKm: distance
        )

        let activeEnergyBurned = workout.statistics(for: HKQuantityTypeCatalog.activeEnergyBurned)?
            .sumQuantity()?
            .doubleValue(for: HKUnitCatalog.kilocalorie) ?? 0

        let heartRateSeries = tupleSeries(samples.heartRate)
        let cadenceSeries = tupleSeries(samples.cadence)
        let powerSeries = tupleSeries(samples.power)

        let splits = WorkoutSplitCalculator.makeSplits(
            route: routeExtraction.samples,
            heartRate: heartRateSeries,
            cadence: cadenceSeries,
            power: powerSeries
        )
        let series = makeWorkoutSeries(
            heartRate: heartRateSeries,
            pace: tupleSeries(samples.paceSecondsPerKm),
            cadence: cadenceSeries,
            power: powerSeries,
            verticalOscillation: tupleSeries(samples.verticalOscillation),
            groundContactTime: tupleSeries(samples.groundContactTime),
            strideLength: tupleSeries(samples.strideLength),
            route: routeExtraction.samples
        )

        return HealthKitWorkout(
            id: workout.uuid,
            runningType: resolveRunningType(from: workout, distanceKm: distance),
            distance: distance,
            duration: workout.duration,
            averagePaceSecondsPerKm: averagePaceSecondsPerKm,
            averageHeartRate: averageQuantity(
                from: workout,
                type: HKQuantityTypeCatalog.heartRate,
                unit: HKUnitCatalog.bpm,
                fallbackSamples: samples.heartRate
            ).map(Int.init) ?? 0,
            // cadence는 stepCount(cumulative) 기반이라 통계 평균이 없어 시계열 산술평균을 사용한다.
            averageCadence: MetricSample.average(of: samples.cadence).map(Int.init) ?? 0,
            activeEnergyBurned: activeEnergyBurned,
            totalEnergyBurned: activeEnergyBurned + (basalEnergyBurned ?? 0),
            elevationAscended: resolveElevationAscended(from: workout, route: routeExtraction.route),
            averageVerticalOscillation: averageQuantity(
                from: workout,
                type: HKQuantityTypeCatalog.runningVerticalOscillation,
                unit: HKUnitCatalog.centimeter,
                fallbackSamples: samples.verticalOscillation
            ) ?? 0,
            averageGroundContactTime: averageQuantity(
                from: workout,
                type: HKQuantityTypeCatalog.runningGroundContactTime,
                unit: HKUnitCatalog.millisecond,
                fallbackSamples: samples.groundContactTime
            ) ?? 0,
            averageStepLength: averageQuantity(
                from: workout,
                type: HKQuantityTypeCatalog.walkingStepLength,
                unit: HKUnitCatalog.meter,
                fallbackSamples: samples.stepLength
            ) ?? 0,
            restingHeartRate: restingHeartRate,
            averagePower: averageQuantity(
                from: workout,
                type: HKQuantityTypeCatalog.runningPower,
                unit: HKUnitCatalog.watt,
                fallbackSamples: samples.power
            ) ?? 0,
            averageStrideLength: averageQuantity(
                from: workout,
                type: HKQuantityTypeCatalog.runningStrideLength,
                unit: HKUnitCatalog.meter,
                fallbackSamples: samples.strideLength
            ) ?? 0,
            heartRateRecoveryOneMinute: heartRateRecoveryOneMinute,
            route: routeExtraction.route,
            startDate: workout.startDate,
            endDate: workout.endDate,
            splits: splits,
            laps: laps,
            series: series,
            zoneSummaries: zoneSummaries,
            samples: samples
        )
    }

    /// 워크아웃에 연관된 discrete 지표의 평균을 HealthKit이 저장 시 산출한 통계에서 조회한다.
    /// 통계가 없으면(일부 서드파티 소스) 이미 조회한 시계열의 산술평균으로 폴백한다.
    private func averageQuantity(
        from workout: HKWorkout,
        type: HKQuantityType,
        unit: HKUnit,
        fallbackSamples: [MetricSample]
    ) -> Double? {
        if let average = workout.statistics(for: type)?.averageQuantity()?.doubleValue(for: unit) {
            return average
        }

        return MetricSample.average(of: fallbackSamples)
    }

    /// 실내 여부 메타데이터를 우선 사용하고, 없으면 거리 측정 여부로 러닝 타입을 추정한다.
    private func resolveRunningType(from workout: HKWorkout, distanceKm: Double) -> RunningType {
        let isIndoorWorkout = workout.metadata?[HKMetadataKeyIndoorWorkout] as? Bool

        return RunningTypeResolver.resolve(isIndoorWorkout: isIndoorWorkout, distanceKm: distanceKm)
    }

    /// 등반 고도는 워크아웃 메타데이터를 우선 사용하고, 없으면 경로 고도의 누적 상승분으로 폴백한다.
    private func resolveElevationAscended(from workout: HKWorkout, route: [RoutePoint]) -> Double? {
        if let quantity = workout.metadata?[HKMetadataKeyElevationAscended] as? HKQuantity {
            return quantity.doubleValue(for: HKUnitCatalog.meter)
        }

        return ElevationCalculator.ascent(of: route.compactMap(\.altitude))
    }

    /// 기초대사 에너지는 워크아웃 통계에 포함되지 않는 소스가 있어 통계 → 구간 합계 순으로 조회한다.
    private func fetchBasalEnergyBurned(for workout: HKWorkout) async -> Double? {
        if let sum = workout.statistics(for: HKQuantityTypeCatalog.basalEnergyBurned)?
            .sumQuantity()?
            .doubleValue(for: HKUnitCatalog.kilocalorie) {
            return sum
        }

        return await fetchCumulativeSum(
            from: workout.startDate,
            to: workout.endDate,
            type: HKQuantityTypeCatalog.basalEnergyBurned,
            unit: HKUnitCatalog.kilocalorie
        )
    }

    /// 휴식 심박수는 하루 단위로 기록되므로 workout 날짜의 전체 하루를 조회
    func fetchAverageRestingHeartRate(for workout: HKWorkout) async -> Double? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: workout.startDate)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return nil }

        return await fetchAverageQuantityForDateRange(
            from: startOfDay,
            to: endOfDay,
            type: HKQuantityTypeCatalog.restingHeartRate,
            unit: HKUnitCatalog.bpm
        )
    }

    /// 1분 심박수 회복은 운동 종료 후 측정되므로 종료 시간부터 5분까지 확장 조회
    func fetchHeartRateRecoveryOneMinute(for workout: HKWorkout) async -> Double? {
        let extendedEnd = workout.endDate.addingTimeInterval(5 * 60) // 운동 종료 후 5분

        return await fetchAverageQuantityForDateRange(
            from: workout.endDate,
            to: extendedEnd,
            type: HKQuantityTypeCatalog.heartRateRecoveryOneMinute,
            unit: HKUnitCatalog.bpm
        )
    }

    /// 특정 날짜 범위에 대해 평균값을 조회하는 공통 헬퍼
    private func fetchAverageQuantityForDateRange(
        from startDate: Date,
        to endDate: Date,
        type: HKQuantityType,
        unit: HKUnit
    ) async -> Double? {
        await fetchStatistics(from: startDate, to: endDate, type: type, options: .discreteAverage) {
            $0.averageQuantity()?.doubleValue(for: unit)
        }
    }

    /// 특정 날짜 범위에 대해 누적 합계를 조회하는 공통 헬퍼
    private func fetchCumulativeSum(
        from startDate: Date,
        to endDate: Date,
        type: HKQuantityType,
        unit: HKUnit
    ) async -> Double? {
        await fetchStatistics(from: startDate, to: endDate, type: type, options: .cumulativeSum) {
            $0.sumQuantity()?.doubleValue(for: unit)
        }
    }

    private func fetchStatistics(
        from startDate: Date,
        to endDate: Date,
        type: HKQuantityType,
        options: HKStatisticsOptions,
        extract: @escaping @Sendable (HKStatistics) -> Double?
    ) async -> Double? {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        return await withCheckedContinuation { (continuation: CheckedContinuation<Double?, Never>) in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: options
            ) { _, statistics, error in
                // 에러 발생 시 (데이터 없음 포함) nil 반환
                guard error == nil, let statistics else {
                    continuation.resume(returning: nil)
                    return
                }

                continuation.resume(returning: extract(statistics))
            }
            healthStore.execute(query)
        }
    }

    /// `MetricSample` 배열을 splits·series 빌더가 요구하는 (경과초, 값) 튜플 시계열로 변환한다.
    private func tupleSeries(_ samples: [MetricSample]) -> [(offset: TimeInterval, value: Double)] {
        samples.map { (offset: $0.offsetSec, value: $0.value) }
    }
}
