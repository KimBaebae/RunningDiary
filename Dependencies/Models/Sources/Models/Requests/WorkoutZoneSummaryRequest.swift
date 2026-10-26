//
//  WorkoutZoneSummaryRequest.swift
//  Models
//
//  Created by Claude on 9/8/26.
//

/// `workout.zoneSummaries[].durations` 배열 원소.
///
/// 옵셔널 필드는 합성 `Encodable`의 `encodeIfPresent` 대신 `encode(to:)`를 직접 구현해
/// `nil`을 키 생략이 아닌 명시적 `null`로 인코딩한다. 계약 문서가 `Number | null`처럼
/// 값의 존재 자체를 스키마로 규정하므로 "키 없음"과 "null"을 섞으면 안 되기 때문이다.
public struct WorkoutZoneDurationRequest: Encodable, Equatable, Sendable {
    public let index: Int
    public let minimum: Double?
    public let maximum: Double?
    public let durationSec: Int

    public init(
        index: Int,
        minimum: Double?,
        maximum: Double?,
        durationSec: Int
    ) {
        self.index = index
        self.minimum = minimum
        self.maximum = maximum
        self.durationSec = durationSec
    }

    private enum CodingKeys: String, CodingKey {
        case index
        case minimum
        case maximum
        case durationSec
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(index, forKey: .index)
        try container.encode(minimum, forKey: .minimum)
        try container.encode(maximum, forKey: .maximum)
        try container.encode(durationSec, forKey: .durationSec)
    }
}

/// `workout.zoneSummaries` 배열 원소.
///
/// `source`는 합성 `Encodable`의 `encodeIfPresent` 대신 `encode(to:)`를 직접 구현해
/// `nil`을 키 생략이 아닌 명시적 `null`로 인코딩한다. 계약 문서가 `String | null`처럼
/// 값의 존재 자체를 스키마로 규정하므로 "키 없음"과 "null"을 섞으면 안 되기 때문이다.
public struct WorkoutZoneSummaryRequest: Encodable, Equatable, Sendable {
    public let metric: String
    public let source: String?
    public let durations: [WorkoutZoneDurationRequest]

    public init(
        metric: String,
        source: String?,
        durations: [WorkoutZoneDurationRequest]
    ) {
        self.metric = metric
        self.source = source
        self.durations = durations
    }

    private enum CodingKeys: String, CodingKey {
        case metric
        case source
        case durations
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(metric, forKey: .metric)
        try container.encode(source, forKey: .source)
        try container.encode(durations, forKey: .durations)
    }
}
