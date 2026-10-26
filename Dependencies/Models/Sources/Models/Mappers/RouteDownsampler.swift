//
//  RouteDownsampler.swift
//  Models
//
//  Created by 김혜지 on 8/3/26.
//

/// 서버 전송용 경로 다운샘플러.
///
/// 엔티티가 보유한 `HealthKitWorkout.route`는 지도 렌더링 품질을 위해 원본을 그대로 유지한다.
/// 서버 계약이 정한 상한은 전송 시점에만 적용하므로, 요청 DTO 매퍼가 이 타입을 호출한다.
public enum RouteDownsampler {
    /// 서버 계약이 허용하는 최대 경로 지점 수.
    public static let defaultMaxPoints = 50_000

    /// 다운샘플 결과와 그 이력.
    public struct Output: Equatable, Sendable {
        public let points: [RoutePoint]
        public let originalPointCount: Int
        public let samplingMethod: SeriesSamplingMethod

        public init(
            points: [RoutePoint],
            originalPointCount: Int,
            samplingMethod: SeriesSamplingMethod
        ) {
            self.points = points
            self.originalPointCount = originalPointCount
            self.samplingMethod = samplingMethod
        }
    }

    /// 경로를 `maxPoints` 이하로 축소한다.
    ///
    /// 상한 이하면 원본을 그대로 쓰고, 초과하면 균등 인덱스로 선택하되 첫·마지막 지점은 보존한다.
    /// 같은 입력에는 항상 같은 출력이 나오며 좌표와 시간 순서를 유지한다.
    public static func downsample(
        _ route: [RoutePoint],
        maxPoints: Int = defaultMaxPoints
    ) -> Output {
        let originalCount = route.count

        guard originalCount > maxPoints, maxPoints > 0 else {
            return Output(
                points: route,
                originalPointCount: originalCount,
                samplingMethod: .none
            )
        }

        return Output(
            points: uniformlyReduced(route, maxPoints: maxPoints),
            originalPointCount: originalCount,
            samplingMethod: .uniform
        )
    }

    /// 배열을 `maxPoints` 이하로 균등 축소한다. 첫·마지막 원소를 보존하고 순서를 유지하며,
    /// 같은 입력에는 항상 같은 출력이 나온다.
    public static func uniformlyReduced<T>(_ items: [T], maxPoints: Int) -> [T] {
        let originalCount = items.count

        guard originalCount > maxPoints, maxPoints > 0 else { return items }

        // 양 끝을 고정하고 그 사이를 균등 분할해야 배열의 시작·종료 원소가 밀리지 않는다.
        // maxPoints가 1이면 나눌 사이 구간이 없으므로 첫 원소만 남긴다.
        guard maxPoints > 1 else { return [items[0]] }

        let stride = Double(originalCount - 1) / Double(maxPoints - 1)
        var reduced: [T] = []
        reduced.reserveCapacity(maxPoints)

        for index in 0..<maxPoints {
            let sourceIndex = min(Int((Double(index) * stride).rounded()), originalCount - 1)
            reduced.append(items[sourceIndex])
        }

        return reduced
    }
}
