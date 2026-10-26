//
//  WorkoutLapRequest.swift
//  Models
//
//  Created by Claude on 9/8/26.
//

/// `workout.laps` 배열 원소.
///
/// 옵셔널 필드는 합성 `Encodable`의 `encodeIfPresent` 대신 `encode(to:)`를 직접 구현해
/// `nil`을 키 생략이 아닌 명시적 `null`로 인코딩한다. 계약 문서가 `Number | null`처럼
/// 값의 존재 자체를 스키마로 규정하므로 "키 없음"과 "null"을 섞으면 안 되기 때문이다.
public struct WorkoutLapRequest: Encodable, Equatable, Sendable {
    public let id: String
    public let index: Int
    public let startOffsetSec: Int
    public let durationSec: Int
    public let distanceKm: Double
    public let paceSecondsPerKm: Int?
    public let averageHeartRate: Int?
    public let averagePower: Double?
    public let averageCadence: Int?

    public init(
        id: String,
        index: Int,
        startOffsetSec: Int,
        durationSec: Int,
        distanceKm: Double,
        paceSecondsPerKm: Int?,
        averageHeartRate: Int?,
        averagePower: Double?,
        averageCadence: Int?
    ) {
        self.id = id
        self.index = index
        self.startOffsetSec = startOffsetSec
        self.durationSec = durationSec
        self.distanceKm = distanceKm
        self.paceSecondsPerKm = paceSecondsPerKm
        self.averageHeartRate = averageHeartRate
        self.averagePower = averagePower
        self.averageCadence = averageCadence
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case index
        case startOffsetSec
        case durationSec
        case distanceKm
        case paceSecondsPerKm
        case averageHeartRate
        case averagePower
        case averageCadence
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(index, forKey: .index)
        try container.encode(startOffsetSec, forKey: .startOffsetSec)
        try container.encode(durationSec, forKey: .durationSec)
        try container.encode(distanceKm, forKey: .distanceKm)
        try container.encode(paceSecondsPerKm, forKey: .paceSecondsPerKm)
        try container.encode(averageHeartRate, forKey: .averageHeartRate)
        try container.encode(averagePower, forKey: .averagePower)
        try container.encode(averageCadence, forKey: .averageCadence)
    }
}
