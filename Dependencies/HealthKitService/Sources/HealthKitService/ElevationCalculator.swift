//
//  ElevationCalculator.swift
//  HealthKitService
//
//  Created by 김혜지 on 7/30/26.
//

/// 고도 샘플에서 누적 상승고도를 산출하는 순수 계산 타입.
/// HealthKit 타입에 의존하지 않고 고도 값만 입출력하여 단위 테스트가 가능하다.
public enum ElevationCalculator {
    /// 고도 샘플의 양(+) 변화량 합, 즉 누적 상승고도(m)를 반환한다. 샘플이 없으면 nil.
    /// 하강분은 무시하므로 오르내림이 반복되는 코스도 총 상승분만 누적된다.
    public static func ascent(of altitudes: [Double]) -> Double? {
        guard !altitudes.isEmpty else { return nil }

        var gain = 0.0
        for index in 1..<altitudes.count {
            let delta = altitudes[index] - altitudes[index - 1]
            if delta > 0 {
                gain += delta
            }
        }
        return gain
    }
}
