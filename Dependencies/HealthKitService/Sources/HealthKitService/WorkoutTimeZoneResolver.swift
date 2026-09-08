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
    /// 메타데이터가 없거나(서드파티 소스 등) 알 수 없는 identifier면 `nil`을 반환한다.
    /// 기기 현재 타임존으로 대체하지 않는 이유는, 모르는 값을 아는 값처럼 저장하지 않기 위해서다.
    /// 해외에서 기록한 워크아웃을 귀국 후 전송하면 기기 현재값은 기록 당시와 다른데도
    /// 서버는 그것이 대체값이었다는 사실을 알 방법이 없다. `nil`로 두면 폴백 정책의 결정 권한이
    /// 서버로 넘어간다.
    public static func resolve(identifier: String?) -> TimeZone? {
        guard
            let identifier,
            let timeZone = TimeZone(identifier: identifier)
        else { return nil }

        return timeZone
    }
}
