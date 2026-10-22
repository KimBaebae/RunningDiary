//
//  SeriesSamplingMetadata.swift
//  Models
//
//  Created by 김혜지 on 8/3/26.
//

/// 다운샘플에 적용한 축약 방식.
public enum SeriesSamplingMethod: String, Sendable, Equatable, Codable, CaseIterable {
    case none                  // 원본 배열을 그대로 사용
    case fixedIntervalAverage  // 고정 시간 버킷의 산술평균으로 축약
    case uniform               // 최대 개수에 맞춰 균등 인덱스로 선택
}

/// `WorkoutSeries`가 담는 시계열 지표.
public enum SeriesMetric: String, Sendable, Equatable, Hashable, Codable, CaseIterable {
    case heartRate
    case paceSecondsPerKm
    case cadence
    case power
    case verticalOscillation
    case groundContactTime
    case strideLength
    case elevation
}

/// 지표 하나의 다운샘플 이력.
///
/// 서버가 전송된 포인트 수만 보고는 "원본이 원래 적었는지" 와 "축약해서 줄었는지" 를 구분할 수 없다.
/// 원본 개수와 적용 방식을 함께 보내 해상도 손실 여부를 판단할 수 있게 한다.
public struct SeriesSamplingMetadata: Equatable, Sendable, Codable {
    public let originalSampleCount: Int      // 다운샘플 전 원본 샘플 개수
    public let samplingMethod: SeriesSamplingMethod

    public init(originalSampleCount: Int, samplingMethod: SeriesSamplingMethod) {
        self.originalSampleCount = originalSampleCount
        self.samplingMethod = samplingMethod
    }
}
