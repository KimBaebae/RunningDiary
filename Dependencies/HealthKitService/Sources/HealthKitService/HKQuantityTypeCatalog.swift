//
//  HKQuantityTypeCatalog.swift
//  HealthKitService
//
//  Created by 김혜지 on 7/30/26.
//

import HealthKit

/// 반복 조회하는 `HKQuantityType`을 한 번만 생성해 재사용한다.
/// `HKQuantityType.quantityType(forIdentifier:)`는 호출마다 식별자 룩업을 수행하므로
/// 워크아웃마다 십여 회씩 호출하는 경로에서는 캐싱이 유리하다.
enum HKQuantityTypeCatalog {
    static let heartRate = HKQuantityType(.heartRate)
    static let restingHeartRate = HKQuantityType(.restingHeartRate)
    static let heartRateRecoveryOneMinute = HKQuantityType(.heartRateRecoveryOneMinute)
    static let distanceWalkingRunning = HKQuantityType(.distanceWalkingRunning)
    static let activeEnergyBurned = HKQuantityType(.activeEnergyBurned)
    static let basalEnergyBurned = HKQuantityType(.basalEnergyBurned)
    static let stepCount = HKQuantityType(.stepCount)
    static let runningSpeed = HKQuantityType(.runningSpeed)
    static let runningPower = HKQuantityType(.runningPower)
    static let runningVerticalOscillation = HKQuantityType(.runningVerticalOscillation)
    static let runningGroundContactTime = HKQuantityType(.runningGroundContactTime)
    static let runningStrideLength = HKQuantityType(.runningStrideLength)
    static let walkingStepLength = HKQuantityType(.walkingStepLength)
}

/// 자주 쓰는 단위 묶음.
enum HKUnitCatalog {
    static let bpm = HKUnit.count().unitDivided(by: .minute())
    static let kilometer = HKUnit.meterUnit(with: .kilo)
    static let kilocalorie = HKUnit.kilocalorie()
    static let centimeter = HKUnit.meterUnit(with: .centi)
    static let millisecond = HKUnit.secondUnit(with: .milli)
    static let meter = HKUnit.meter()
    static let watt = HKUnit.watt()
    static let meterPerSecond = HKUnit.meter().unitDivided(by: .second())
}
