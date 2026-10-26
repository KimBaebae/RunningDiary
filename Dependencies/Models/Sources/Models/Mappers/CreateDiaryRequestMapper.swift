//
//  CreateDiaryRequestMapper.swift
//  Models
//
//  Created by Claude on 9/8/26.
//

import Foundation

/// `Diary` → `POST /api/v1/running-logs` 요청 바디(`CreateDiaryRequest`) 변환.
///
/// 계약 문서: `docs/api/create-diary-request.md`
public enum CreateDiaryRequestMapper {
    public static func request(from diary: Diary) -> CreateDiaryRequest {
        CreateDiaryRequest(
            workout: workoutRequest(from: diary.workout),
            weather: weatherRequest(from: diary.weather),
            painAreas: diary.painAreas.map(\.rawValue),
            runningStyle: diary.runningStyle?.rawValue,
            memo: normalizedMemo(diary.memo),
            // legacyShoe는 카탈로그 식별자가 없는 로컬 전용 데이터라 서버가 해석할 수 없으므로
            // shoe.id만 사용하고, legacyShoe는 무시한 채 null로 대체한다.
            shoeId: diary.shoe?.id,
            difficultyLevel: diary.difficultyLevel?.rawValue
        )
    }

    private static func workoutRequest(from workout: HealthKitWorkout) -> WorkoutRequest {
        let route = routeOutput(from: workout)

        return WorkoutRequest(
            // UUID는 소문자로 고정한다. 계약 문서 예시가 소문자이고, 서버의 중복 방지가
            // (userId, workout.id) 문자열 비교이므로 표기를 한 곳에서 고정해야 한다.
            id: workout.id.uuidString.lowercased(),
            startTime: workout.startTime.formatted(.iso8601),
            endTime: workout.endTime.formatted(.iso8601),
            timeZone: workout.timeZone?.identifier,
            runningType: workout.runningType.rawValue,
            distance: workout.distance,
            duration: Int(workout.duration.rounded()),
            elapsedTime: Int(workout.elapsedTime.rounded()),
            averagePaceSecondsPerKm: workout.averagePaceSecondsPerKm,
            averageHeartRate: workout.averageHeartRate,
            averageCadence: workout.averageCadence,
            averagePower: workout.averagePower,
            averageVerticalOscillation: workout.averageVerticalOscillation,
            averageGroundContactTime: workout.averageGroundContactTime,
            averageStepLength: workout.averageStepLength,
            averageStrideLength: workout.averageStrideLength,
            activeEnergyBurned: workout.activeEnergyBurned,
            totalEnergyBurned: workout.totalEnergyBurned,
            elevationAscended: workout.elevationAscended,
            restingHeartRate: workout.restingHeartRate,
            heartRateRecoveryOneMinute: workout.heartRateRecoveryOneMinute,
            route: route.points,
            routeOriginalPointCount: route.originalPointCount,
            routeSamplingMethod: route.samplingMethod,
            splits: workout.splits.map(splitRequest(from:)),
            laps: workout.laps.map(lapRequest(from:)),
            zoneSummaries: workout.zoneSummaries.map(zoneSummaryRequest(from:)),
            series: seriesRequest(from: workout.series)
        )
    }

    private struct RouteOutput {
        let points: [RoutePointRequest]?
        let originalPointCount: Int
        let samplingMethod: String
    }

    private static func routeOutput(from workout: HealthKitWorkout) -> RouteOutput {
        // 경로가 없거나 비어 있거나, 트레드밀이면 route: null로 정규화한다.
        // 트레드밀은 좌표가 남아있어도 null이어야 한다 — 계약 문서가 서버에
        // "treadmill인데 route가 존재하는 조합은 나오지 않는다"고 보장했으므로,
        // 전송 직전 마지막 관문인 이 매퍼가 그 보장을 성립시켜야 한다.
        guard
            let route = workout.route,
            !route.isEmpty,
            workout.runningType != .treadmill
        else {
            return RouteOutput(
                points: nil,
                originalPointCount: 0,
                samplingMethod: SeriesSamplingMethod.none.rawValue
            )
        }

        let downsampled = RouteDownsampler.downsample(route)
        return RouteOutput(
            points: downsampled.points.map(routePointRequest(from:)),
            originalPointCount: downsampled.originalPointCount,
            samplingMethod: downsampled.samplingMethod.rawValue
        )
    }

    private static func routePointRequest(from point: RoutePoint) -> RoutePointRequest {
        RoutePointRequest(
            latitude: point.latitude,
            longitude: point.longitude,
            altitude: point.altitude,
            elapsedSec: point.elapsedSec
        )
    }

    private static func splitRequest(from split: WorkoutSplit) -> WorkoutSplitRequest {
        WorkoutSplitRequest(
            index: split.index,
            distanceKm: split.distanceKm,
            durationSec: Int(split.durationSec.rounded()),
            paceSecondsPerKm: split.paceSecondsPerKm,
            averageHeartRate: split.averageHeartRate,
            averageCadence: split.averageCadence,
            averagePower: split.averagePower,
            elevationGainM: split.elevationGainM
        )
    }

    private static func lapRequest(from lap: WorkoutLap) -> WorkoutLapRequest {
        WorkoutLapRequest(
            id: lap.id.uuidString.lowercased(),
            index: lap.index,
            startOffsetSec: Int(lap.startOffsetSec.rounded()),
            durationSec: Int(lap.durationSec.rounded()),
            distanceKm: lap.distanceKm,
            paceSecondsPerKm: lap.paceSecondsPerKm,
            averageHeartRate: lap.averageHeartRate,
            averagePower: lap.averagePower,
            averageCadence: lap.averageCadence
        )
    }

    private static func zoneSummaryRequest(from summary: WorkoutZoneSummary) -> WorkoutZoneSummaryRequest {
        WorkoutZoneSummaryRequest(
            metric: summary.metric.rawValue,
            source: summary.source?.rawValue,
            durations: summary.durations.map(zoneDurationRequest(from:))
        )
    }

    private static func zoneDurationRequest(from duration: WorkoutZoneDuration) -> WorkoutZoneDurationRequest {
        WorkoutZoneDurationRequest(
            index: duration.index,
            minimum: duration.minimum,
            maximum: duration.maximum,
            durationSec: Int(duration.durationSec.rounded())
        )
    }

    private static func seriesRequest(from series: WorkoutSeries?) -> WorkoutSeriesRequest? {
        guard let series else { return nil }

        return WorkoutSeriesRequest(
            sampleIntervalSec: series.sampleIntervalSec,
            heartRate: series.heartRate,
            paceSecondsPerKm: series.paceSecondsPerKm,
            cadence: series.cadence,
            power: series.power,
            verticalOscillation: series.verticalOscillation,
            groundContactTime: series.groundContactTime,
            strideLength: series.strideLength,
            elevation: series.elevation,
            // 딕셔너리 키를 String으로 바꾼다: enum(SeriesMetric)을 키로 갖는 Dictionary는
            // JSON 인코딩 시 객체가 아니라 [key, value, key, value, ...] 평탄 배열이 되어
            // 계약이 요구하는 객체 형태({"heartRate": {...}})와 어긋나기 때문이다.
            metadata: Dictionary(
                uniqueKeysWithValues: series.metadata.map { ($0.key.rawValue, $0.value) }
            )
        )
    }

    private static func weatherRequest(from weather: WeatherData?) -> WeatherRequest? {
        guard let weather else { return nil }

        return WeatherRequest(
            temperature: weather.temperature,
            humidity: weather.humidity,
            windSpeed: weather.windSpeed,
            apparentTemperature: weather.apparentTemperature,
            cloudCover: weather.cloudCover,
            precipitationAmount: weather.precipitationAmount
        )
    }

    private static func normalizedMemo(_ memo: String?) -> String? {
        guard let memo else { return nil }

        let trimmed = memo.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        return String(trimmed.prefix(Constant.memoMaxLength))
    }
}

private enum Constant {
    static let memoMaxLength = 2_000
}
