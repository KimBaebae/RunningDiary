import Foundation
import Models
import Testing

@testable import HealthKitService

@Suite("WorkoutSeriesBuilder.downsample")
struct WorkoutSeriesBuilderTests {

    // MARK: - 빈 입력 / 단일 샘플

    @Test("빈 입력이면 빈 배열을 반환한다")
    func downsample_returnsEmpty_whenSamplesEmpty() {
        // Given
        let samples: [(offset: TimeInterval, value: Double)] = []
        let expectedPoints: [SeriesPoint] = []

        // When
        let result = WorkoutSeriesBuilder.downsample(samples, intervalSec: 5)

        // Then
        #expect(result.points == expectedPoints)
    }

    @Test("단일 샘플은 버킷 규칙대로 t가 계산된 포인트 1개를 반환한다")
    func downsample_returnsSinglePoint_whenSingleSample() {
        // Given
        let samples: [(offset: TimeInterval, value: Double)] = [(offset: 12, value: 100)]
        let expectedPoints = [SeriesPoint(t: 10, v: 100)]

        // When
        let result = WorkoutSeriesBuilder.downsample(samples, intervalSec: 5)

        // Then
        #expect(result.points == expectedPoints)
    }

    // MARK: - 버킷 평균

    @Test("같은 버킷에 속한 샘플은 값이 평균되어 하나의 포인트가 된다")
    func downsample_averagesValues_whenSamplesShareBucket() {
        // Given
        let samples: [(offset: TimeInterval, value: Double)] = [
            (offset: 10, value: 100),
            (offset: 12, value: 110),
            (offset: 14, value: 120),
        ]
        let expectedPoints = [SeriesPoint(t: 10, v: 110)]

        // When
        let result = WorkoutSeriesBuilder.downsample(samples, intervalSec: 5)

        // Then
        #expect(result.points == expectedPoints)
    }

    @Test("서로 다른 버킷의 샘플은 각각 독립된 포인트로 분리된다")
    func downsample_separatesPoints_whenSamplesInDifferentBuckets() {
        // Given
        let samples: [(offset: TimeInterval, value: Double)] = [
            (offset: 10, value: 100),
            (offset: 12, value: 110),
            (offset: 14, value: 120),
            (offset: 20, value: 200),
        ]
        let expectedPoints = [
            SeriesPoint(t: 10, v: 110),
            SeriesPoint(t: 20, v: 200),
        ]

        // When
        let result = WorkoutSeriesBuilder.downsample(samples, intervalSec: 5)

        // Then
        #expect(result.points == expectedPoints)
    }

    // MARK: - maxPoints 상한 / 결정성

    @Test("포인트 개수가 maxPoints를 초과하면 균등 축소되어 정확히 maxPoints개가 된다")
    func downsample_reducesToMaxPoints_whenPointsExceedMaxPoints() {
        // Given
        let samples: [(offset: TimeInterval, value: Double)] = (0..<1_000).map {
            (offset: TimeInterval($0), value: Double($0))
        }
        let maxPoints = 10
        let expectedCount = maxPoints
        let expectedFirstPoint = SeriesPoint(t: 0, v: 0)
        let expectedLastPoint = SeriesPoint(t: 900, v: 900)

        // When
        let result = WorkoutSeriesBuilder.downsample(samples, intervalSec: 1, maxPoints: maxPoints)

        // Then
        #expect(result.points.count == expectedCount)
        #expect(result.points.first == expectedFirstPoint)
        #expect(result.points.last == expectedLastPoint)
    }

    @Test("동일한 입력으로 반복 호출해도 항상 같은 결과를 반환한다")
    func downsample_isDeterministic_whenCalledRepeatedly() {
        // Given
        let samples: [(offset: TimeInterval, value: Double)] = (0..<1_000).map {
            (offset: TimeInterval($0), value: Double($0))
        }
        let maxPoints = 10

        // When
        let firstResult = WorkoutSeriesBuilder.downsample(samples, intervalSec: 1, maxPoints: maxPoints)
        let secondResult = WorkoutSeriesBuilder.downsample(samples, intervalSec: 1, maxPoints: maxPoints)

        // Then
        #expect(firstResult.points == secondResult.points)
        #expect(firstResult.metadata == secondResult.metadata)
    }

    // MARK: - 샘플링 메타데이터

    @Test("기본 상한은 서버 계약과 같은 2000이다")
    func defaultMaxPoints_matchesServerContract() {
        // Given
        let expectedMaxPoints = 2_000

        // Then
        #expect(WorkoutSeriesBuilder.defaultMaxPoints == expectedMaxPoints)
    }

    @Test("상한에 걸리지 않으면 samplingMethod가 fixedIntervalAverage다")
    func downsample_reportsFixedIntervalAverage_whenUnderMaxPoints() {
        // Given
        let samples: [(offset: TimeInterval, value: Double)] = (0..<100).map {
            (offset: TimeInterval($0), value: Double($0))
        }
        let expectedMethod = SeriesSamplingMethod.fixedIntervalAverage
        let expectedOriginalCount = 100

        // When
        let result = WorkoutSeriesBuilder.downsample(samples, intervalSec: 1)

        // Then
        #expect(result.metadata.samplingMethod == expectedMethod)
        #expect(result.metadata.originalSampleCount == expectedOriginalCount)
    }

    @Test("상한을 넘겨 균등 축소되면 samplingMethod가 uniform이고 원본 개수가 보존된다")
    func downsample_reportsUniformAndOriginalCount_whenOverMaxPoints() {
        // Given
        let originalCount = 3_000
        let samples: [(offset: TimeInterval, value: Double)] = (0..<originalCount).map {
            (offset: TimeInterval($0), value: Double($0))
        }
        let expectedMethod = SeriesSamplingMethod.uniform
        let expectedPointCount = WorkoutSeriesBuilder.defaultMaxPoints

        // When
        let result = WorkoutSeriesBuilder.downsample(samples, intervalSec: 1)

        // Then
        #expect(result.points.count == expectedPointCount)
        #expect(result.metadata.samplingMethod == expectedMethod)
        #expect(result.metadata.originalSampleCount == originalCount)
    }

    @Test("버킷 평균으로 상한 이하가 되면 원본이 상한을 넘어도 uniform이 아니다")
    func downsample_reportsFixedIntervalAverage_whenBucketingAloneMeetsCap() {
        // Given - 원본 6000개가 5초 버킷 평균으로 1200개가 되어 상한 2000 이하로 내려간다
        let originalCount = 6_000
        let samples: [(offset: TimeInterval, value: Double)] = (0..<originalCount).map {
            (offset: TimeInterval($0), value: Double($0))
        }
        let expectedMethod = SeriesSamplingMethod.fixedIntervalAverage
        let expectedPointCount = 1_200

        // When
        let result = WorkoutSeriesBuilder.downsample(samples, intervalSec: 5)

        // Then
        #expect(result.points.count == expectedPointCount)
        #expect(result.metadata.samplingMethod == expectedMethod)
        #expect(result.metadata.originalSampleCount == originalCount)
    }

    // MARK: - capPoints (거리축 elevation)

    @Test("capPoints는 상한 이하면 원본을 그대로 두고 none으로 보고한다")
    func capPoints_keepsOriginal_whenUnderMaxPoints() {
        // Given
        let points = (0..<10).map { ElevationPoint(distanceM: Double($0), altitude: Double($0)) }
        let expectedMethod = SeriesSamplingMethod.none

        // When
        let result = WorkoutSeriesBuilder.capPoints(points)

        // Then
        #expect(result.points == points)
        #expect(result.metadata.samplingMethod == expectedMethod)
        #expect(result.metadata.originalSampleCount == points.count)
    }

    @Test("capPoints는 상한을 넘으면 2000개로 균등 축소하고 uniform으로 보고한다")
    func capPoints_reducesToMaxPoints_whenOverMaxPoints() {
        // Given
        let originalCount = 5_000
        let points = (0..<originalCount).map { ElevationPoint(distanceM: Double($0), altitude: Double($0)) }
        let expectedMethod = SeriesSamplingMethod.uniform
        let expectedPointCount = WorkoutSeriesBuilder.defaultMaxPoints

        // When
        let result = WorkoutSeriesBuilder.capPoints(points)

        // Then
        #expect(result.points.count == expectedPointCount)
        #expect(result.metadata.samplingMethod == expectedMethod)
        #expect(result.metadata.originalSampleCount == originalCount)
    }

    // MARK: - 소수 정밀도 보존 (downsampleDecimal)

    @Test("수직 진폭 8.2cm가 정수 반올림 없이 보존된다")
    func downsampleDecimal_preservesFraction_whenValueIsSmall() {
        // Given
        let samples: [(offset: TimeInterval, value: Double)] = [(offset: 0, value: 8.2)]
        let expectedPoints = [MetricSeriesPoint(t: 0, v: 8.2)]

        // When
        let result = WorkoutSeriesBuilder.downsampleDecimal(samples, intervalSec: 5)

        // Then
        #expect(result.points == expectedPoints)
    }

    @Test("같은 버킷의 소수 값도 평균되어 소수로 남는다")
    func downsampleDecimal_averagesValues_preservingFraction() {
        // Given
        let samples: [(offset: TimeInterval, value: Double)] = [
            (offset: 0, value: 1.2),
            (offset: 2, value: 1.4),
        ]
        let expectedValue = 1.3
        let tolerance = 0.0001

        // When
        let result = WorkoutSeriesBuilder.downsampleDecimal(samples, intervalSec: 5)

        // Then
        #expect(result.points.count == 1)
        #expect(result.points.first?.t == 0)
        #expect(abs((result.points.first?.v ?? 0) - expectedValue) < tolerance)
    }

    @Test("정수 다운샘플과 달리 1 미만 값이 0으로 소멸하지 않는다")
    func downsampleDecimal_doesNotCollapseSubUnitValues() {
        // Given
        let samples: [(offset: TimeInterval, value: Double)] = [(offset: 0, value: 0.4)]
        let expectedIntegerValue = 0
        let expectedDecimalValue = 0.4

        // When
        let integerResult = WorkoutSeriesBuilder.downsample(samples, intervalSec: 5)
        let decimalResult = WorkoutSeriesBuilder.downsampleDecimal(samples, intervalSec: 5)

        // Then
        #expect(integerResult.points.first?.v == expectedIntegerValue)
        #expect(decimalResult.points.first?.v == expectedDecimalValue)
    }

    @Test("빈 입력이면 빈 배열을 반환한다")
    func downsampleDecimal_returnsEmpty_whenSamplesEmpty() {
        // Given
        let samples: [(offset: TimeInterval, value: Double)] = []
        let expectedPoints: [MetricSeriesPoint] = []

        // When
        let result = WorkoutSeriesBuilder.downsampleDecimal(samples, intervalSec: 5)

        // Then
        #expect(result.points == expectedPoints)
    }
}
