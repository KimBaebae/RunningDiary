//
//  HealthKitManager.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import CommonFoundation
import CoreLocation
import Foundation
import HealthKit
import Models

public final class HealthKitManager: HealthKitManagerProtocol, @unchecked Sendable {
    // 시계열/구간 추출 확장(HealthKitManager+*)에서 접근하므로 internal
    let healthStore = HKHealthStore()
    let zoneExtractor: WorkoutZoneExtracting

    private let typesToRead: Set<HKObjectType> = [
        HKObjectType.workoutType(),                                                               // workout 타입
        HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,                       // 걷기/달리기 거리
        HKObjectType.quantityType(forIdentifier: .heartRate)!,                                    // 심박수
        HKObjectType.quantityType(forIdentifier: .runningSpeed)!,                                 // 달리기 속도
        HKObjectType.quantityType(forIdentifier: .stepCount)!,                                    // 걸음 수
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,                           // 활동 에너지 소모량
        HKObjectType.quantityType(forIdentifier: .basalEnergyBurned)!,                            // 기초대사 에너지 소모량
        HKObjectType.quantityType(forIdentifier: .runningVerticalOscillation)!,                   // 달리기 수직 진폭
        HKObjectType.quantityType(forIdentifier: .runningGroundContactTime)!,                     // 달리기 지면 접촉 시간
        HKObjectType.quantityType(forIdentifier: .walkingStepLength)!,                            // 걷기 보폭 길이
        HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,                             // 휴식 심박수
        HKObjectType.quantityType(forIdentifier: .runningPower)!,                                 // 달리기 파워
        HKObjectType.quantityType(forIdentifier: .runningStrideLength)!,                          // 달리기 보폭 길이
        HKObjectType.quantityType(forIdentifier: .heartRateRecoveryOneMinute)!,                   // 1분 심박수 회복
        HKSeriesType.workoutRoute(),                                                              // 경로
    ]

    public convenience init() {
        self.init(zoneExtractor: WorkoutZoneExtractorFactory.make())
    }

    /// 존 추출기를 주입하는 초기화. 테스트에서 가짜 추출기를 꽂기 위해 사용한다.
    init(zoneExtractor: WorkoutZoneExtracting) {
        self.zoneExtractor = zoneExtractor
    }

    public func ensureAuthorizationIfNeeded() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        let statuses = currentAuthorizationStatuses()
        let notDetermined = statuses.filter { $0.value == .notDetermined }.map { $0.key }

        guard !notDetermined.isEmpty else { return }

        do {
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
        } catch {
            throw HealthKitError.authorizationFailed
        }
    }

    private func currentAuthorizationStatuses() -> [HKObjectType: HKAuthorizationStatus] {
        var result: [HKObjectType: HKAuthorizationStatus] = [:]
        for type in typesToRead {
            result[type] = healthStore.authorizationStatus(for: type)
        }
        return result
    }

    // 단일 Date에 대한 피트니스 기록을 전체 상세 데이터로 가져옵니다.
    public func fetchRunningData(for date: Date) async throws -> [HealthKitWorkout] {
        try await ensureAuthorizationIfNeeded()

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.endOfDay(for: date) else {
            return []
        }

        let workouts = try await queryWorkouts(start: startOfDay, end: endOfDay)

        // 워크아웃마다 십여 회의 쿼리가 필요하므로 병렬로 조립하고, 완료 순서가 아닌 시작 시각 기준으로 정렬한다.
        let results = await withTaskGroup(of: HealthKitWorkout.self) { group in
            for workout in workouts {
                group.addTask { [self] in
                    await makeWorkout(from: workout)
                }
            }

            var collected: [HealthKitWorkout] = []
            for await result in group {
                collected.append(result)
            }
            return collected
        }

        return results.sorted { $0.startTime > $1.startTime }
    }

    /// 러닝 워크아웃을 날짜 범위로 조회하는 공통 쿼리
    private func queryWorkouts(start: Date, end: Date) async throws -> [HKWorkout] {
        let runningPredicate = HKQuery.predicateForWorkouts(with: .running)
        let datePredicate = HKQuery.predicateForSamples(
            withStart: start,
            end: end,
            options: .strictStartDate
        )
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [runningPredicate, datePredicate])

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKWorkout], Error>) in
            let query = HKSampleQuery(
                sampleType: .workoutType(),
                predicate: compoundPredicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [
                    NSSortDescriptor(
                        key: HKSampleSortIdentifierStartDate,
                        ascending: false
                    ),
                ]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: samples as? [HKWorkout] ?? [])
                }
            }
            healthStore.execute(query)
        }
    }

    // startDate ~ endDate 기간에 대한 피트니스 기록을 가져옵니다.
    public func fetchWeeklyRunningData(from startDate: Date, to endDate: Date) async throws -> [HealthKitWorkout] {
        try await ensureAuthorizationIfNeeded()

        let calendar = Calendar.current

        // 시작일부터 종료일까지의 날짜 배열 생성
        var dates: [Date] = []
        var currentDate = calendar.startOfDay(for: startDate)
        let normalizedEndDate = calendar.startOfDay(for: endDate)

        while currentDate <= normalizedEndDate {
            dates.append(currentDate)
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDate
        }

        // 각 날짜에 대해 병렬로 데이터 조회
        return await withTaskGroup(of: [HealthKitWorkout].self) { group in
            for date in dates {
                group.addTask { [self] in
                    return (try? await self.fetchRunningData(for: date)) ?? []
                }
            }

            // 결과를 하나의 배열로 합침
            var results: [HealthKitWorkout] = []
            for await result in group {
                results.append(contentsOf: result)
            }

            return results
        }
    }
}
