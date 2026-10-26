//
//  WorkoutSampleSet.swift
//  Models
//
//  Created by 김혜지 on 7/30/26.
//

/// 워크아웃 구간의 원시 시계열 묶음. HealthKit이 기록한 샘플을 다운샘플 없이 원본 정밀도로 보존한다.
///
/// 서버 전송 대상이 아니다. 전송에는 다운샘플된 `WorkoutSeries`를 쓰고, 이 원본은
/// 평균 산출과 클라이언트 분석에 사용한다. 영속 왕복 시에는 유실되며 평균은 워크아웃의 스칼라가 보존한다.
///
/// 고도 시계열은 이 묶음에 없다. 경로 지점(`RoutePoint`)이 고도와 경과초를 이미 보유하므로 중복 저장하지 않는다.
public struct WorkoutSampleSet: Equatable, Sendable, Codable {
    public let heartRate: [MetricSample]              // bpm
    public let paceSecondsPerKm: [MetricSample]       // sec/km (runningSpeed 환산)
    public let cadence: [MetricSample]                // spm (stepCount 환산)
    public let power: [MetricSample]                  // watts
    public let verticalOscillation: [MetricSample]    // cm
    public let groundContactTime: [MetricSample]      // ms
    public let stepLength: [MetricSample]             // m
    public let strideLength: [MetricSample]           // m

    public static let empty = WorkoutSampleSet()

    public var isEmpty: Bool {
        heartRate.isEmpty
            && paceSecondsPerKm.isEmpty
            && cadence.isEmpty
            && power.isEmpty
            && verticalOscillation.isEmpty
            && groundContactTime.isEmpty
            && stepLength.isEmpty
            && strideLength.isEmpty
    }

    public init(
        heartRate: [MetricSample] = [],
        paceSecondsPerKm: [MetricSample] = [],
        cadence: [MetricSample] = [],
        power: [MetricSample] = [],
        verticalOscillation: [MetricSample] = [],
        groundContactTime: [MetricSample] = [],
        stepLength: [MetricSample] = [],
        strideLength: [MetricSample] = []
    ) {
        self.heartRate = heartRate
        self.paceSecondsPerKm = paceSecondsPerKm
        self.cadence = cadence
        self.power = power
        self.verticalOscillation = verticalOscillation
        self.groundContactTime = groundContactTime
        self.stepLength = stepLength
        self.strideLength = strideLength
    }
}
