//
//  PaceMapper.swift
//  Models
//
//  Created by 김혜지 on 7/30/26.
//

import Foundation

/// 페이스의 표준 표현은 `Int`(sec/km)이며, 이 매퍼가 표시 문자열과 거리·시간 기반 산출을 담당한다.
/// 표시 계층 전용이 아니라 영속 계층(문자열 컬럼 채우기)에서도 필요하므로 Models에 둔다.
public enum PaceMapper {
    /// sec/km를 `분'초"` 표시 문자열로 변환한다. (예: 344 → `5'44"`)
    public static func string(fromSecondsPerKm secondsPerKm: Int) -> String {
        guard secondsPerKm > 0 else { return "" }

        let minutes = secondsPerKm / 60
        let seconds = secondsPerKm % 60
        return String(format: "%d'%02d\"", minutes, seconds)
    }

    /// 운동시간과 거리로 평균 페이스(sec/km)를 산출한다. 거리가 0 이하면 nil.
    public static func secondsPerKm(fromDurationSec durationSec: TimeInterval, distanceKm: Double) -> Int? {
        guard distanceKm > 0, durationSec > 0 else { return nil }

        return Int((durationSec / distanceKm).rounded())
    }
}
