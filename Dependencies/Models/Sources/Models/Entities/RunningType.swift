//
//  RunningType.swift
//  Models
//
//  Created by 김혜지 on 7/30/26.
//

/// 달리기 수행 환경. HealthKit의 `HKMetadataKeyIndoorWorkout`을 우선 근거로 판별하고,
/// 메타데이터가 없으면 거리 측정 여부로 추정한다. (판별 규칙은 `RunningTypeResolver` 참고)
public enum RunningType: String, Sendable, Codable, CaseIterable {
    case outdoor      // 실외 달리기
    case treadmill    // 트레드밀 (실내)
}
