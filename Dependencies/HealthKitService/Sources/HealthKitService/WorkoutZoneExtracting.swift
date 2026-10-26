//
//  WorkoutZoneExtracting.swift
//  HealthKitService
//
//  Created by 김혜지 on 7/30/26.
//

import HealthKit
import Models

/// 워크아웃 존(심박·파워) 추출 seam.
///
/// HealthKit 존 API(`HKWorkoutZoneGroup` 등)는 iOS 27부터 제공되며, iOS 27 SDK가 없는 툴체인에서는
/// 심볼 자체가 존재하지 않아 `@available`로 감싸도 컴파일되지 않는다. 따라서 존 심볼을 참조하는 코드는
/// 이 파일이 아니라 `RUNDIARY_WORKOUT_ZONES` 플래그로 격리된 별도 파일에만 둔다.
///
/// 활성화 절차:
/// 1. iOS 27 SDK 툴체인에서 `HKWorkoutZoneExtractor.swift`를 추가한다.
/// 2. `Package.swift`의 타깃에 `swiftSettings: [.define("RUNDIARY_WORKOUT_ZONES")]`를 추가한다.
protocol WorkoutZoneExtracting: Sendable {
    func zoneSummaries(for workout: HKWorkout, healthStore: HKHealthStore) async -> [WorkoutZoneSummary]
}

/// iOS 27 미만 또는 iOS 27 SDK 미보유 툴체인용 기본 구현. 항상 빈 배열을 반환한다.
struct UnavailableWorkoutZoneExtractor: WorkoutZoneExtracting {
    func zoneSummaries(for workout: HKWorkout, healthStore: HKHealthStore) async -> [WorkoutZoneSummary] {
        []
    }
}

enum WorkoutZoneExtractorFactory {
    static func make() -> WorkoutZoneExtracting {
        #if RUNDIARY_WORKOUT_ZONES
        if #available(iOS 27.0, *) {
            return HKWorkoutZoneExtractor()
        }
        #endif
        return UnavailableWorkoutZoneExtractor()
    }
}
