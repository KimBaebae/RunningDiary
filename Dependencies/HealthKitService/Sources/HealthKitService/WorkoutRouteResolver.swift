//
//  WorkoutRouteResolver.swift
//  HealthKitService
//
//  Created by 김혜지 on 8/4/26.
//

import Models

/// 워크아웃에 실을 경로를 판별하는 순수 계산 타입.
public enum WorkoutRouteResolver {
    /// 도메인과 서버 계약 모두 "경로 없음"을 `nil`로 표현하므로 빈 배열을 만들지 않는다.
    ///
    /// 트레드밀은 정의상 경로가 없다. HealthKit이 좌표를 남겼더라도 버려서
    /// "트레드밀인데 경로가 있는" 모순된 조합이 나오지 않게 정규화한다.
    public static func resolve(runningType: RunningType, points: [RoutePoint]) -> [RoutePoint]? {
        guard runningType != .treadmill, !points.isEmpty else { return nil }

        return points
    }
}
