//
//  RunningTypeResolver.swift
//  HealthKitService
//
//  Created by 김혜지 on 7/30/26.
//

import Models

/// 워크아웃이 실외 달리기인지 트레드밀인지 판별하는 순수 계산 타입.
public enum RunningTypeResolver {
    /// `isIndoorWorkout`(HealthKit `HKMetadataKeyIndoorWorkout`)을 1순위 근거로 사용한다.
    /// 메타데이터가 없는 워크아웃(서드파티 소스 등)은 거리 측정 여부로 추정하며,
    /// 거리가 0이면 GPS를 쓰지 않은 실내 러닝으로 간주한다.
    public static func resolve(isIndoorWorkout: Bool?, distanceKm: Double) -> RunningType {
        if let isIndoorWorkout {
            return isIndoorWorkout ? .treadmill : .outdoor
        }

        return distanceKm > 0 ? .outdoor : .treadmill
    }
}
