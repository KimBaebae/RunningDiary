//
//  WorkoutRequest.swift
//  Models
//
//  Created by Claude on 9/8/26.
//

/// `HealthKitWorkout` → `workout` 요청 필드 매핑.
///
/// 옵셔널 필드는 합성 `Encodable`의 `encodeIfPresent` 대신 `encode(to:)`를 직접 구현해
/// `nil`을 키 생략이 아닌 명시적 `null`로 인코딩한다. 계약 문서가 `String | null`처럼
/// 값의 존재 자체를 스키마로 규정하므로 "키 없음"과 "null"을 섞으면 안 되기 때문이다.
///
/// `runningTypeSource`는 필드로 두지 않는다. 엔티티에는 있지만 이번 계약에서 전송하지
/// 않기로 확정됐다(계약 문서 "전송 제외 항목" 참고).
public struct WorkoutRequest: Encodable, Equatable, Sendable {
    public let id: String
    public let startTime: String
    public let endTime: String
    public let timeZone: String?
    public let runningType: String
    public let distance: Double
    public let duration: Int
    public let elapsedTime: Int
    public let averagePaceSecondsPerKm: Int?
    public let averageHeartRate: Int
    public let averageCadence: Int
    public let averagePower: Double
    public let averageVerticalOscillation: Double
    public let averageGroundContactTime: Double
    public let averageStepLength: Double
    public let averageStrideLength: Double
    public let activeEnergyBurned: Double
    public let totalEnergyBurned: Double?
    public let elevationAscended: Double?
    public let restingHeartRate: Double
    public let heartRateRecoveryOneMinute: Double
    public let route: [RoutePointRequest]?
    public let routeOriginalPointCount: Int
    public let routeSamplingMethod: String
    public let splits: [WorkoutSplitRequest]
    public let laps: [WorkoutLapRequest]
    public let zoneSummaries: [WorkoutZoneSummaryRequest]
    public let series: WorkoutSeriesRequest?

    public init(
        id: String,
        startTime: String,
        endTime: String,
        timeZone: String?,
        runningType: String,
        distance: Double,
        duration: Int,
        elapsedTime: Int,
        averagePaceSecondsPerKm: Int?,
        averageHeartRate: Int,
        averageCadence: Int,
        averagePower: Double,
        averageVerticalOscillation: Double,
        averageGroundContactTime: Double,
        averageStepLength: Double,
        averageStrideLength: Double,
        activeEnergyBurned: Double,
        totalEnergyBurned: Double?,
        elevationAscended: Double?,
        restingHeartRate: Double,
        heartRateRecoveryOneMinute: Double,
        route: [RoutePointRequest]?,
        routeOriginalPointCount: Int,
        routeSamplingMethod: String,
        splits: [WorkoutSplitRequest],
        laps: [WorkoutLapRequest],
        zoneSummaries: [WorkoutZoneSummaryRequest],
        series: WorkoutSeriesRequest?
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.timeZone = timeZone
        self.runningType = runningType
        self.distance = distance
        self.duration = duration
        self.elapsedTime = elapsedTime
        self.averagePaceSecondsPerKm = averagePaceSecondsPerKm
        self.averageHeartRate = averageHeartRate
        self.averageCadence = averageCadence
        self.averagePower = averagePower
        self.averageVerticalOscillation = averageVerticalOscillation
        self.averageGroundContactTime = averageGroundContactTime
        self.averageStepLength = averageStepLength
        self.averageStrideLength = averageStrideLength
        self.activeEnergyBurned = activeEnergyBurned
        self.totalEnergyBurned = totalEnergyBurned
        self.elevationAscended = elevationAscended
        self.restingHeartRate = restingHeartRate
        self.heartRateRecoveryOneMinute = heartRateRecoveryOneMinute
        self.route = route
        self.routeOriginalPointCount = routeOriginalPointCount
        self.routeSamplingMethod = routeSamplingMethod
        self.splits = splits
        self.laps = laps
        self.zoneSummaries = zoneSummaries
        self.series = series
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case startTime
        case endTime
        case timeZone
        case runningType
        case distance
        case duration
        case elapsedTime
        case averagePaceSecondsPerKm
        case averageHeartRate
        case averageCadence
        case averagePower
        case averageVerticalOscillation
        case averageGroundContactTime
        case averageStepLength
        case averageStrideLength
        case activeEnergyBurned
        case totalEnergyBurned
        case elevationAscended
        case restingHeartRate
        case heartRateRecoveryOneMinute
        case route
        case routeOriginalPointCount
        case routeSamplingMethod
        case splits
        case laps
        case zoneSummaries
        case series
    }

    /// route 3필드(`route`·`routeOriginalPointCount`·`routeSamplingMethod`)만 교체한 복사본을 만든다.
    ///
    /// 필드가 28개라 매번 전체 이니셜라이저를 손으로 채우면 새 필드 추가 시 이 호출부만
    /// 조용히 누락되기 쉽다. route 관련 필드를 재구성하는 지점을 이 메서드 하나로 모아
    /// 이니셜라이저 호출을 한 곳에만 둔다. `routeOriginalPointCount`는 최초 원본 개수를
    /// 유지해야 하므로 `self`의 값을 그대로 전달한다(파라미터로 받지 않는다).
    public func replacingRoute(points: [RoutePointRequest]?, samplingMethod: String) -> WorkoutRequest {
        WorkoutRequest(
            id: id,
            startTime: startTime,
            endTime: endTime,
            timeZone: timeZone,
            runningType: runningType,
            distance: distance,
            duration: duration,
            elapsedTime: elapsedTime,
            averagePaceSecondsPerKm: averagePaceSecondsPerKm,
            averageHeartRate: averageHeartRate,
            averageCadence: averageCadence,
            averagePower: averagePower,
            averageVerticalOscillation: averageVerticalOscillation,
            averageGroundContactTime: averageGroundContactTime,
            averageStepLength: averageStepLength,
            averageStrideLength: averageStrideLength,
            activeEnergyBurned: activeEnergyBurned,
            totalEnergyBurned: totalEnergyBurned,
            elevationAscended: elevationAscended,
            restingHeartRate: restingHeartRate,
            heartRateRecoveryOneMinute: heartRateRecoveryOneMinute,
            route: points,
            routeOriginalPointCount: routeOriginalPointCount,
            routeSamplingMethod: samplingMethod,
            splits: splits,
            laps: laps,
            zoneSummaries: zoneSummaries,
            series: series
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(startTime, forKey: .startTime)
        try container.encode(endTime, forKey: .endTime)
        try container.encode(timeZone, forKey: .timeZone)
        try container.encode(runningType, forKey: .runningType)
        try container.encode(distance, forKey: .distance)
        try container.encode(duration, forKey: .duration)
        try container.encode(elapsedTime, forKey: .elapsedTime)
        try container.encode(averagePaceSecondsPerKm, forKey: .averagePaceSecondsPerKm)
        try container.encode(averageHeartRate, forKey: .averageHeartRate)
        try container.encode(averageCadence, forKey: .averageCadence)
        try container.encode(averagePower, forKey: .averagePower)
        try container.encode(averageVerticalOscillation, forKey: .averageVerticalOscillation)
        try container.encode(averageGroundContactTime, forKey: .averageGroundContactTime)
        try container.encode(averageStepLength, forKey: .averageStepLength)
        try container.encode(averageStrideLength, forKey: .averageStrideLength)
        try container.encode(activeEnergyBurned, forKey: .activeEnergyBurned)
        try container.encode(totalEnergyBurned, forKey: .totalEnergyBurned)
        try container.encode(elevationAscended, forKey: .elevationAscended)
        try container.encode(restingHeartRate, forKey: .restingHeartRate)
        try container.encode(heartRateRecoveryOneMinute, forKey: .heartRateRecoveryOneMinute)
        try container.encode(route, forKey: .route)
        try container.encode(routeOriginalPointCount, forKey: .routeOriginalPointCount)
        try container.encode(routeSamplingMethod, forKey: .routeSamplingMethod)
        try container.encode(splits, forKey: .splits)
        try container.encode(laps, forKey: .laps)
        try container.encode(zoneSummaries, forKey: .zoneSummaries)
        try container.encode(series, forKey: .series)
    }
}
