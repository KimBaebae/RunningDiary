//
//  WorkoutSeries.swift
//  Models
//
//  Created by 김혜지 on 7/12/26.
//

/// 서버 전송용 **다운샘플** 시계열. 원본은 `WorkoutSampleSet`(전송 제외)이 보유한다.
///
/// 다운샘플 방식: `sampleIntervalSec`(기본 5초) 버킷별 산술평균으로 축약한 뒤 최대 포인트 수 이하로
/// 균등 축소한다. `SeriesPoint`(Int) 계열은 정수로 반올림하고, 값의 크기가 작아 반올림 시 정보가
/// 소멸하는 지표(`MetricSeriesPoint` 계열)는 소수 정밀도를 보존한다. 산출은 `WorkoutSeriesBuilder`가 담당한다.
///
/// `elevation`만 시간축이 아니라 거리축(`distanceM`) 프로파일이며, 경로 지점에서 직접 도출한다.
public struct WorkoutSeries: Equatable, Sendable, Codable {
    public let sampleIntervalSec: Int?
    public let heartRate: [SeriesPoint]                    // bpm
    public let paceSecondsPerKm: [SeriesPoint]             // sec/km
    public let cadence: [SeriesPoint]                      // spm
    public let power: [SeriesPoint]                        // watts
    public let verticalOscillation: [MetricSeriesPoint]    // cm
    public let groundContactTime: [SeriesPoint]            // ms
    public let strideLength: [MetricSeriesPoint]           // m
    public let elevation: [ElevationPoint]                 // 거리축 고도 프로파일

    /// 지표별 다운샘플 이력. 수집하지 못한 지표는 키가 없다.
    public let metadata: [SeriesMetric: SeriesSamplingMetadata]

    public init(
        sampleIntervalSec: Int?,
        heartRate: [SeriesPoint],
        paceSecondsPerKm: [SeriesPoint],
        cadence: [SeriesPoint],
        power: [SeriesPoint] = [],
        verticalOscillation: [MetricSeriesPoint] = [],
        groundContactTime: [SeriesPoint] = [],
        strideLength: [MetricSeriesPoint] = [],
        elevation: [ElevationPoint],
        metadata: [SeriesMetric: SeriesSamplingMetadata] = [:]
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
}
