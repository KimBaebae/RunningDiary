//
//  HealthKitManager+ZoneExtraction.swift
//  HealthKitService
//
//  Created by 김혜지 on 7/30/26.
//

import HealthKit
import Models

extension HealthKitManager {
    /// 심박·파워 영역 요약을 조회한다.
    ///
    /// 실제 추출은 주입된 `WorkoutZoneExtracting`이 담당한다. iOS 27 SDK가 없는 툴체인에서는
    /// 기본 구현이 항상 빈 배열을 반환하므로, 존 UI·서버 계약을 미리 확정해도 빌드가 깨지지 않는다.
    func fetchZoneSummaries(for workout: HKWorkout) async -> [WorkoutZoneSummary] {
        await zoneExtractor.zoneSummaries(for: workout, healthStore: healthStore)
    }
}
