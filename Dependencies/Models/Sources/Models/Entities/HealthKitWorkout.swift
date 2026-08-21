//
//  HealthKitWorkout.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import CommonFoundation
import Foundation

public struct HealthKitWorkout: Equatable, Identifiable, Sendable {
    // MARK: 식별 · 시간
    public let id: UUID                                 // 고유 식별자 (HealthKit 유래 시 HKWorkout.uuid)
    public let yearMonthDay: YearMonthDay               // 달리기 날짜
    public let startTime: Date                          // 달리기 시작 시간
    public let endTime: Date                            // 달리기 종료 시간
    public let timeZone: TimeZone                       // 기록 당시 타임존. 영속되지 않아 복원 시 .current
    public let duration: TimeInterval                   // 운동시간 (sec, 일시정지 제외)
    public let elapsedTime: TimeInterval                // 경과시간 (sec, 일시정지 포함)
    public let runningType: RunningType                 // 실외 달리기 / 트레드밀

    // MARK: 거리 · 에너지 · 고도
    public let distance: Double                         // 총 거리 (km)
    public let activeEnergyBurned: Double               // 활동 칼로리 (kcal)
    public let totalEnergyBurned: Double                // 총 칼로리 (kcal, 활동 + 기초대사)
    public let elevationAscended: Double?               // 등반 고도 (m). 미측정 시 nil

    // MARK: 평균
    public let averagePaceSecondsPerKm: Int?            // 평균 페이스 (sec/km). 거리 미측정 시 nil
    public let averageHeartRate: Int                    // 평균 심박수 (bpm)
    public let averageCadence: Int                      // 평균 케이던스 (spm)
    public let averagePower: Double                     // 평균 러닝 파워 (watts)
    public let averageVerticalOscillation: Double       // 평균 수직 진폭 (cm)
    public let averageGroundContactTime: Double         // 평균 지면 접촉 시간 (ms)
    public let averageStepLength: Double                // 평균 보폭 (m)
    public let averageStrideLength: Double              // 평균 러닝 보폭 길이 (m)

    // MARK: 심박 부가
    public let restingHeartRate: Double                 // 휴식 심박수 (bpm)
    public let heartRateRecoveryOneMinute: Double       // 운동 후 1분 심박수 회복 (bpm)
    public let zoneSummaries: [WorkoutZoneSummary]      // 심박·파워 영역. iOS 27 미만이면 빈 배열

    // MARK: 경로 · 구간 · 시계열
    public let route: [RoutePoint]?                     // 달리기 경로. 없으면 nil. 트레드밀은 항상 nil
    public let splits: [WorkoutSplit]                   // 1km 단위 스플릿
    public let laps: [WorkoutLap]                       // 랩 버튼으로 구분된 구간
    public let series: WorkoutSeries?                   // 다운샘플 시계열 (서버 전송 대상)

    // MARK: 원시 시계열 (HealthKit 조회 시에만 채워지고 영속 왕복 시 유실됨. 평균은 위 stored 스칼라가 보존한다.)
    public let samples: WorkoutSampleSet

    /// 심박 영역별 체류 시간. 존이 없으면 빈 배열.
    public var heartRateZones: [WorkoutZoneDuration] {
        zoneSummaries.first { $0.metric == .heartRate }?.durations ?? []
    }

    public var formattedDuration: String {
        formatted(duration)
    }

    public var formattedElapsedTime: String {
        formatted(elapsedTime)
    }

    public var formattedDistance: String {
        distance == 0 ? "" : distance.to2f
    }

    public var formattedAveragePace: String {
        averagePaceSecondsPerKm.map(PaceMapper.string(fromSecondsPerKm:)) ?? ""
    }

    public var formattedAverageHeartRate: String {
        averageHeartRate == 0 ? "" : averageHeartRate.toString
    }

    public var formattedAverageCadence: String {
        averageCadence == 0 ? "" : averageCadence.toString
    }

    public var formattedActiveEnergyBurned: String {
        activeEnergyBurned == 0 ? "" : activeEnergyBurned.to1f
    }

    public var formattedTotalEnergyBurned: String {
        totalEnergyBurned == 0 ? "" : totalEnergyBurned.to1f
    }

    public var formattedElevationAscended: String {
        guard let elevationAscended, elevationAscended > 0 else { return "" }

        return elevationAscended.to0f
    }

    public var formattedAveragePower: String {
        averagePower == 0 ? "" : averagePower.to0f
    }

    public var formattedAverageVerticalOscillation: String {
        averageVerticalOscillation == 0 ? "" : averageVerticalOscillation.to1f
    }

    public var formattedAverageGroundContactTime: String {
        averageGroundContactTime == 0 ? "" : averageGroundContactTime.to0f
    }

    public init(
        id: UUID = UUID(),
        runningType: RunningType = .outdoor,
        distance: Double,
        duration: TimeInterval,
        elapsedTime: TimeInterval? = nil,
        averagePaceSecondsPerKm: Int?,
        averageHeartRate: Int,
        averageCadence: Int,
        activeEnergyBurned: Double,
        totalEnergyBurned: Double = 0,
        elevationAscended: Double? = nil,
        averageVerticalOscillation: Double,
        averageGroundContactTime: Double,
        averageStepLength: Double,
        restingHeartRate: Double,
        averagePower: Double,
        averageStrideLength: Double,
        heartRateRecoveryOneMinute: Double,
        route: [RoutePoint]? = nil,
        startDate: Date,
        endDate: Date,
        timeZone: TimeZone = .current,
        splits: [WorkoutSplit] = [],
        laps: [WorkoutLap] = [],
        series: WorkoutSeries? = nil,
        zoneSummaries: [WorkoutZoneSummary] = [],
        samples: WorkoutSampleSet = .empty
    ) {
        self.id = id
        self.yearMonthDay = YearMonthDay(date: startDate)
        self.startTime = startDate
        self.endTime = endDate
        self.timeZone = timeZone
        self.duration = duration
        self.elapsedTime = elapsedTime ?? endDate.timeIntervalSince(startDate)
        self.runningType = runningType
        self.distance = distance
        self.activeEnergyBurned = activeEnergyBurned
        self.totalEnergyBurned = totalEnergyBurned
        self.elevationAscended = elevationAscended
        self.averagePaceSecondsPerKm = averagePaceSecondsPerKm
        self.averageHeartRate = averageHeartRate
        self.averageCadence = averageCadence
        self.averagePower = averagePower
        self.averageVerticalOscillation = averageVerticalOscillation
        self.averageGroundContactTime = averageGroundContactTime
        self.averageStepLength = averageStepLength
        self.averageStrideLength = averageStrideLength
        self.restingHeartRate = restingHeartRate
        self.heartRateRecoveryOneMinute = heartRateRecoveryOneMinute
        self.zoneSummaries = zoneSummaries
        self.route = route
        self.splits = splits
        self.laps = laps
        self.series = series
        self.samples = samples
    }

    private func formatted(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}
