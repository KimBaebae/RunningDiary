//
//  WorkoutSeriesRequest.swift
//  Models
//
//  Created by Claude on 9/8/26.
//

/// `workout.series` 객체.
///
/// `sampleIntervalSec`는 합성 `Encodable`의 `encodeIfPresent` 대신 `encode(to:)`를 직접
/// 구현해 `nil`을 키 생략이 아닌 명시적 `null`로 인코딩한다. 계약 문서가 `Integer | null`처럼
/// 값의 존재 자체를 스키마로 규정하므로 "키 없음"과 "null"을 섞으면 안 되기 때문이다.
///
/// `heartRate`·`paceSecondsPerKm`·`cadence`·`power`·`groundContactTime`은 엔티티의
/// `SeriesPoint`를, `verticalOscillation`·`strideLength`는 `MetricSeriesPoint`를,
/// `elevation`은 `ElevationPoint`를 그대로 재사용한다. 셋 다 옵셔널 프로퍼티가 없고
/// 필드명이 계약과 정확히 일치하며, `SeriesPoint`/`MetricSeriesPoint`의 `t`/`v`는 애초에
/// 이 JSON 스키마(`{t, v}`)에 맞추려고 지어진 이름이다.
///
/// `metadata`는 엔티티(`[SeriesMetric: SeriesSamplingMetadata]`)와 달리 키 타입이
/// `String`이다. Swift는 enum을 키로 갖는 딕셔너리를 JSON 객체가 아니라 평탄 배열
/// (`["heartRate", {...}, "power", {...}]`)로 인코딩하는데, 계약은 `{"heartRate": {...}}`
/// 형태의 객체를 요구하므로 매퍼가 `SeriesMetric.rawValue`를 키로 변환해 이 타입에 담는다.
public struct WorkoutSeriesRequest: Encodable, Equatable, Sendable {
    public let sampleIntervalSec: Int?
    public let heartRate: [SeriesPoint]
    public let paceSecondsPerKm: [SeriesPoint]
    public let cadence: [SeriesPoint]
    public let power: [SeriesPoint]
    public let verticalOscillation: [MetricSeriesPoint]
    public let groundContactTime: [SeriesPoint]
    public let strideLength: [MetricSeriesPoint]
    public let elevation: [ElevationPoint]
    public let metadata: [String: SeriesSamplingMetadata]

    public init(
        sampleIntervalSec: Int?,
        heartRate: [SeriesPoint],
        paceSecondsPerKm: [SeriesPoint],
        cadence: [SeriesPoint],
        power: [SeriesPoint],
        verticalOscillation: [MetricSeriesPoint],
        groundContactTime: [SeriesPoint],
        strideLength: [MetricSeriesPoint],
        elevation: [ElevationPoint],
        metadata: [String: SeriesSamplingMetadata]
    ) {
        self.sampleIntervalSec = sampleIntervalSec
        self.heartRate = heartRate
        self.paceSecondsPerKm = paceSecondsPerKm
        self.cadence = cadence
        self.power = power
        self.verticalOscillation = verticalOscillation
        self.groundContactTime = groundContactTime
        self.strideLength = strideLength
        self.elevation = elevation
        self.metadata = metadata
    }

    private enum CodingKeys: String, CodingKey {
        case sampleIntervalSec
        case heartRate
        case paceSecondsPerKm
        case cadence
        case power
        case verticalOscillation
        case groundContactTime
        case strideLength
        case elevation
        case metadata
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(sampleIntervalSec, forKey: .sampleIntervalSec)
        try container.encode(heartRate, forKey: .heartRate)
        try container.encode(paceSecondsPerKm, forKey: .paceSecondsPerKm)
        try container.encode(cadence, forKey: .cadence)
        try container.encode(power, forKey: .power)
        try container.encode(verticalOscillation, forKey: .verticalOscillation)
        try container.encode(groundContactTime, forKey: .groundContactTime)
        try container.encode(strideLength, forKey: .strideLength)
        try container.encode(elevation, forKey: .elevation)
        try container.encode(metadata, forKey: .metadata)
    }
}
