//
//  WorkoutSeriesBuilder.swift
//  HealthKitService
//
//  Created by 김혜지 on 7/13/26.
//

import Foundation
import Models

/// 시작 후 경과초(offset)·값 샘플을 시계열 포인트로 가공하는 순수 계산 타입.
/// HealthKit 타입에 의존하지 않고 원시 값(offset, value)만 입출력하여 단위 테스트가 가능하다.
public enum WorkoutSeriesBuilder {
    /// 서버 계약이 지표당 허용하는 최대 포인트 수.
    public static let defaultMaxPoints = 2_000

    /// 다운샘플 결과와 그 이력.
    public struct Output<Point> {
        public let points: [Point]
        public let metadata: SeriesSamplingMetadata
    }

    /// 샘플을 `intervalSec` 버킷 단위로 평균낸 뒤 `maxPoints` 이하로 균등 축소한다.
    /// 값은 정수로 반올림되므로 심박수·페이스·케이던스처럼 정수 표현으로 충분한 지표에 쓴다.
    public static func downsample(
        _ samples: [(offset: TimeInterval, value: Double)],
        intervalSec: Int,
        maxPoints: Int = defaultMaxPoints
    ) -> Output<SeriesPoint> {
        let averages = bucketAverages(samples, intervalSec: intervalSec)
        let points = averages.map { SeriesPoint(t: $0.offsetSec, v: Int($0.value.rounded())) }

        return makeOutput(points, originalCount: samples.count, maxPoints: maxPoints)
    }

    /// `downsample`과 동일하게 축약하되 소수 정밀도를 보존한다.
    /// 수직 진폭(cm)·보폭 길이(m)처럼 값이 작아 정수 반올림 시 정보가 소멸하는 지표에 쓴다.
    public static func downsampleDecimal(
        _ samples: [(offset: TimeInterval, value: Double)],
        intervalSec: Int,
        maxPoints: Int = defaultMaxPoints
    ) -> Output<MetricSeriesPoint> {
        let averages = bucketAverages(samples, intervalSec: intervalSec)
        let points = averages.map { MetricSeriesPoint(t: $0.offsetSec, v: $0.value) }

        return makeOutput(points, originalCount: samples.count, maxPoints: maxPoints)
    }

    /// 이미 축약이 끝난 배열에 개수 상한만 적용한다.
    /// 거리축이라 시간 버킷 평균을 쓸 수 없는 `elevation`에 사용한다.
    public static func capPoints<Point>(
        _ points: [Point],
        maxPoints: Int = defaultMaxPoints
    ) -> Output<Point> {
        let reduced = reduceToMaxPoints(points, maxPoints: maxPoints)

        return Output(
            points: reduced,
            metadata: SeriesSamplingMetadata(
                originalSampleCount: points.count,
                samplingMethod: reduced.count < points.count ? .uniform : .none
            )
        )
    }

    /// 버킷 평균까지 마친 포인트에 상한을 적용하고 실제로 적용된 방식을 기록한다.
    private static func makeOutput<Point>(
        _ points: [Point],
        originalCount: Int,
        maxPoints: Int
    ) -> Output<Point> {
        let reduced = reduceToMaxPoints(points, maxPoints: maxPoints)
        // 상한에 걸려 한 번 더 줄었으면 균등 선택이 최종 방식이고,
        // 그대로 통과했으면 버킷 평균이 최종 방식이다.
        let method: SeriesSamplingMethod = reduced.count < points.count ? .uniform : .fixedIntervalAverage

        return Output(
            points: reduced,
            metadata: SeriesSamplingMetadata(
                originalSampleCount: originalCount,
                samplingMethod: method
            )
        )
    }

    /// 샘플을 `intervalSec` 버킷으로 묶어 버킷별 산술평균을 경과초 오름차순으로 반환한다.
    private static func bucketAverages(
        _ samples: [(offset: TimeInterval, value: Double)],
        intervalSec: Int
    ) -> [(offsetSec: Int, value: Double)] {
        guard !samples.isEmpty, intervalSec > 0 else { return [] }

        var bucketSums: [Int: (sum: Double, count: Int)] = [:]
        for sample in samples {
            let bucket = Int(sample.offset / Double(intervalSec))
            var entry = bucketSums[bucket] ?? (sum: 0, count: 0)
            entry.sum += sample.value
            entry.count += 1
            bucketSums[bucket] = entry
        }

        return bucketSums.keys.sorted().compactMap { bucket -> (offsetSec: Int, value: Double)? in
            guard let entry = bucketSums[bucket] else { return nil }

            return (offsetSec: bucket * intervalSec, value: entry.sum / Double(entry.count))
        }
    }

    /// `points`가 `maxPoints`를 초과하면 균등 간격으로 골라 결정적으로 축소한다.
    private static func reduceToMaxPoints<Point>(_ points: [Point], maxPoints: Int) -> [Point] {
        guard points.count > maxPoints, maxPoints > 0 else { return points }

        let stride = Double(points.count) / Double(maxPoints)
        var reduced: [Point] = []
        for index in 0..<maxPoints {
            let sourceIndex = min(Int(Double(index) * stride), points.count - 1)
            reduced.append(points[sourceIndex])
        }
        return reduced
    }
}
