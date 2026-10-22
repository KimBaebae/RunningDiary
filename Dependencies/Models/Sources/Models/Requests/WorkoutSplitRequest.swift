//
//  WorkoutSplitRequest.swift
//  Models
//
//  Created by Claude on 9/8/26.
//

/// `workout.splits` 배열 원소.
///
/// 옵셔널 필드는 합성 `Encodable`의 `encodeIfPresent` 대신 `encode(to:)`를 직접 구현해
/// `nil`을 키 생략이 아닌 명시적 `null`로 인코딩한다. 계약 문서가 `Number | null`처럼
/// 값의 존재 자체를 스키마로 규정하므로 "키 없음"과 "null"을 섞으면 안 되기 때문이다.
public struct WorkoutSplitRequest: Encodable, Equatable, Sendable {
    public let index: Int
    public let distanceKm: Double
    public let durationSec: Int
    public let paceSecondsPerKm: Int
    public let averageHeartRate: Int?
    public let averageCadence: Int?
    public let averagePower: Double?
    public let elevationGainM: Double?

    public init(
        index: Int,
        distanceKm: Double,
        durationSec: Int,
        paceSecondsPerKm: Int,
        averageHeartRate: Int?,
        averageCadence: Int?,
        averagePower: Double?,
        elevationGainM: Double?
    ) {
        self.index = index
        self.distanceKm = distanceKm
        self.durationSec = durationSec
        self.paceSecondsPerKm = paceSecondsPerKm
        self.averageHeartRate = averageHeartRate
        self.averageCadence = averageCadence
        self.averagePower = averagePower
        self.elevationGainM = elevationGainM
    }

    private enum CodingKeys: String, CodingKey {
        case index
        case distanceKm
        case durationSec
        case paceSecondsPerKm
        case averageHeartRate
        case averageCadence
        case averagePower
        case elevationGainM
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(index, forKey: .index)
        try container.encode(distanceKm, forKey: .distanceKm)
        try container.encode(durationSec, forKey: .durationSec)
        try container.encode(paceSecondsPerKm, forKey: .paceSecondsPerKm)
        try container.encode(averageHeartRate, forKey: .averageHeartRate)
        try container.encode(averageCadence, forKey: .averageCadence)
        try container.encode(averagePower, forKey: .averagePower)
        try container.encode(elevationGainM, forKey: .elevationGainM)
    }
}
