//
//  HealthKitManager+SeriesExtraction.swift
//  RunDiary
//
//  Created by 김혜지 on 7/13/26.
//

import CoreLocation
import Foundation
import HealthKit
import Models

private enum Constant {
    static let seriesIntervalSec = 5
}

/// 경로 조회 결과. `route`는 도메인 경로(좌표·고도·경과초), `samples`는 splits/series 계산용 원시 값(경과초·누적거리·고도).
struct RouteExtractionResult {
    let route: [RoutePoint]
    let samples: [(offset: TimeInterval, cumulativeMeters: Double, altitude: Double?)]

    static let empty = RouteExtractionResult(route: [], samples: [])
}

/// `HKWorkoutRouteQuery`는 배치 콜백을 여러 번 호출하므로 누적 버퍼가 필요하다.
/// 콜백이 직렬로 전달되므로 참조 타입 버퍼로 누적해 캡처 변수 변경 경고 없이 수집한다.
private final class LocationBuffer: @unchecked Sendable {
    private var locations: [CLLocation] = []

    func append(_ batch: [CLLocation]) {
        locations.append(contentsOf: batch)
    }

    var all: [CLLocation] {
        locations
    }
}

extension HealthKitManager {
    /// 시계열이 하나라도 존재하면 `WorkoutSeries`를 구성한다. 전부 비어 있으면 nil.
    func makeWorkoutSeries(
        heartRate: [(offset: TimeInterval, value: Double)],
        pace: [(offset: TimeInterval, value: Double)],
        cadence: [(offset: TimeInterval, value: Double)],
        power: [(offset: TimeInterval, value: Double)],
        verticalOscillation: [(offset: TimeInterval, value: Double)],
        groundContactTime: [(offset: TimeInterval, value: Double)],
        strideLength: [(offset: TimeInterval, value: Double)],
        route: [(offset: TimeInterval, cumulativeMeters: Double, altitude: Double?)]
    ) -> WorkoutSeries? {
        let isEmpty = heartRate.isEmpty
            && pace.isEmpty
            && cadence.isEmpty
            && power.isEmpty
            && verticalOscillation.isEmpty
            && groundContactTime.isEmpty
            && strideLength.isEmpty
            && route.isEmpty
        guard !isEmpty else { return nil }

        let rawElevation = route.compactMap { sample -> ElevationPoint? in
            guard let altitude = sample.altitude else { return nil }
            return ElevationPoint(distanceM: sample.cumulativeMeters, altitude: altitude)
        }

        let interval = Constant.seriesIntervalSec

        // 거리축이라 시간 버킷 평균을 쓸 수 없어 개수 상한만 적용한다.
        let elevation = WorkoutSeriesBuilder.capPoints(rawElevation)
        let heartRateOutput = WorkoutSeriesBuilder.downsample(heartRate, intervalSec: interval)
        let paceOutput = WorkoutSeriesBuilder.downsample(pace, intervalSec: interval)
        let cadenceOutput = WorkoutSeriesBuilder.downsample(cadence, intervalSec: interval)
        let powerOutput = WorkoutSeriesBuilder.downsample(power, intervalSec: interval)
        // 수직 진폭(cm)·보폭 길이(m)는 값이 작아 정수 반올림 시 정보가 소멸하므로 소수 정밀도를 유지한다.
        let verticalOscillationOutput = WorkoutSeriesBuilder.downsampleDecimal(
            verticalOscillation,
            intervalSec: interval
        )
        let groundContactTimeOutput = WorkoutSeriesBuilder.downsample(groundContactTime, intervalSec: interval)
        let strideLengthOutput = WorkoutSeriesBuilder.downsampleDecimal(strideLength, intervalSec: interval)

        let metadata: [SeriesMetric: SeriesSamplingMetadata] = [
            .heartRate: heartRateOutput.metadata,
            .paceSecondsPerKm: paceOutput.metadata,
            .cadence: cadenceOutput.metadata,
            .power: powerOutput.metadata,
            .verticalOscillation: verticalOscillationOutput.metadata,
            .groundContactTime: groundContactTimeOutput.metadata,
            .strideLength: strideLengthOutput.metadata,
            .elevation: elevation.metadata,
        ].filter { $0.value.originalSampleCount > 0 }

        return WorkoutSeries(
            sampleIntervalSec: interval,
            heartRate: heartRateOutput.points,
            paceSecondsPerKm: paceOutput.points,
            cadence: cadenceOutput.points,
            power: powerOutput.points,
            verticalOscillation: verticalOscillationOutput.points,
            groundContactTime: groundContactTimeOutput.points,
            strideLength: strideLengthOutput.points,
            elevation: elevation.points,
            metadata: metadata
        )
    }
}

extension HealthKitManager {
    /// 워크아웃 경로를 조회한다. 경로가 없거나 조회에 실패하면 빈 결과를 반환한다.
    func fetchRouteExtractionResult(for workout: HKWorkout) async -> RouteExtractionResult {
        (try? await fetchRouteData(for: workout)) ?? .empty
    }

    func fetchRouteData(for workout: HKWorkout) async throws -> RouteExtractionResult {
        let routeType = HKSeriesType.workoutRoute()
        let predicate = HKQuery.predicateForObjects(from: workout)

        let routes = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKWorkoutRoute], Error>) in
            let query = HKSampleQuery(
                sampleType: routeType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(
                        returning: samples as? [HKWorkoutRoute] ?? []
                    )
                }
            }
            healthStore.execute(query)
        }

        guard let route = routes.first else {
            return .empty
        }

        let locations = try await fetchLocations(of: route)

        return RouteExtractionResult(
            route: makeRoutePoints(from: locations, workoutStart: workout.startDate),
            samples: makeRouteSamples(from: locations, workoutStart: workout.startDate)
        )
    }

    /// 경로 샘플의 좌표를 배치 단위로 모두 수집한다.
    private func fetchLocations(of route: HKWorkoutRoute) async throws -> [CLLocation] {
        let buffer = LocationBuffer()

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[CLLocation], Error>) in
            let query = HKWorkoutRouteQuery(route: route) { _, batch, done, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                if let batch = batch {
                    buffer.append(batch)
                }

                if done {
                    continuation.resume(returning: buffer.all)
                }
            }
            healthStore.execute(query)
        }
    }

    /// `CLLocation`을 도메인 경로 지점으로 변환한다. 고도와 워크아웃 시작 후 경과초를 함께 보존한다.
    func makeRoutePoints(from locations: [CLLocation], workoutStart: Date) -> [RoutePoint] {
        locations.map { location in
            RoutePoint(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                altitude: location.altitude,
                elapsedSec: location.timestamp.timeIntervalSince(workoutStart)
            )
        }
    }

    /// `CLLocation`의 timestamp·altitude·좌표를 splits/series 계산용 원시 샘플(경과초·누적거리·고도)로 변환한다.
    func makeRouteSamples(
        from locations: [CLLocation],
        workoutStart: Date
    ) -> [(offset: TimeInterval, cumulativeMeters: Double, altitude: Double?)] {
        var samples: [(offset: TimeInterval, cumulativeMeters: Double, altitude: Double?)] = []
        var cumulativeMeters: Double = 0
        var previousLocation: CLLocation?

        for location in locations {
            if let previousLocation {
                cumulativeMeters += location.distance(from: previousLocation)
            }

            samples.append((
                offset: location.timestamp.timeIntervalSince(workoutStart),
                cumulativeMeters: cumulativeMeters,
                altitude: location.altitude
            ))
            previousLocation = location
        }

        return samples
    }
}
