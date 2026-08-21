//
//  WorkoutTimeZoneResolver.swift
//  HealthKitService
//
//  Created by 김혜지 on 8/3/26.
//

import Foundation

/// 워크아웃을 기록한 당시의 타임존을 판별하는 순수 계산 타입.
public enum WorkoutTimeZoneResolver {
    /// 기록 기기가 `HKMetadataKeyIndoorWorkout`과 같은 방식으로 남기는
    /// `HKMetadataKeyTimeZone`의 IANA identifier를 1순위 근거로 사용한다.
    ///
    /// 메타데이터가 없거나(서드파티 소스 등) 알 수 없는 identifier면 기기 현재 타임존으로 대체한다.
    /// 서버 계약은 시각을 UTC로 보내고 이 타임존을 별도 필드로 함께 보내므로,
    /// 대체값이 쓰이면 해외 기록의 현지 시각 해석이 어긋날 수 있다.
    public static func resolve(identifier: String?) -> TimeZone {
        guard
            let identifier,
            let timeZone = TimeZone(identifier: identifier)
        else { return .current }

        return timeZone
    }
}
