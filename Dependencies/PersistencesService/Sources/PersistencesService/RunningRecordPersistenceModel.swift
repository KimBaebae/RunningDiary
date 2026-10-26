//
//  RunningRecordPersistenceModel.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import Foundation
import Models
import SwiftData

/// SwiftData 영속 전용 스키마 모델. 도메인 계층에는 직접 노출하지 않고
/// `toDomain()` / `fromDomain(_:)`을 통해서만 도메인 타입 `Diary`와 왕복한다.
@Model
public final class RunningRecordPersistenceModel {
    @Attribute(.unique)
    public var id: UUID
    public var date: Date                               // 달리기 날짜
    public var distance: Double                         // 달리기 거리 (km)
    public var duration: TimeInterval                   // 달리기 시간 (sec)
    public var averagePace: String                      // 평균 페이스 (min/km)
    public var averageHeartRate: Int                    // 평균 심박수 (bpm)
    public var averageCadence: Int                      // 평균 케이던스 (spm)
    public var painAreasRawData: String?                // 통증 부위 (raw)
    public var runningStyleRaw: String?                 // 달리기 스타일 (raw)
    public var memo: String?                            // 메모
    public var shoes: String?                           // 신발
    public var temperature: Double?                     // 온도 (ºC)
    public var humidity: Int?                           // 습도 (%)
    public var windSpeed: Double?                       // 풍속 (m/s)
    public var skyConditionRaw: String?                 // 유저 선택 - 하늘 상태 (raw)
    public var windLevelRaw: String?                    // 유저 선택 - 바람 세기 (raw)
    public var feelsLikeRaw: String?                    // 유저 선택 - 체감 온도 (raw)
    public var humidityLevelRaw: String?                // 유저 선택 - 습도 체감 (raw)
    public var difficultyLevelRaw: Int?                 // 달리기 난이도 (raw)
    public var routeData: Data?                         // 달리기 경로 데이터
    public var activeEnergyBurned: Double?              // 활동 에너지 소모량 (kcal)
    public var runningVerticalOscillation: Double?      // 수직 진폭 (cm)
    public var runningGroundContactTime: Double?        // 지면 접촉 시간 (ms)
    public var walkingStepLength: Double?               // 보폭 (m)
    public var restingHeartRate: Double?                // 휴식 심박수 (bpm)
    public var runningPower: Double?                    // 러닝 파워 (watts)
    public var runningStrideLength: Double?             // 러닝 보폭 길이 (m)
    public var heartRateRecoveryOneMinute: Double?      // 1분 심박수 회복 (bpm)
    public var startTime: Date                          // 달리기 시작 시간
    public var endTime: Date                            // 달리기 종료 시간

    public init(
        id: UUID = UUID(),
        date: Date = Date.now,
        distance: Double,
        duration: TimeInterval,
        averagePace: String,
        averageHeartRate: Int,
        averageCadence: Int,
        painAreasRaw: [String] = [],
        runningStyleRaw: String?,
        memo: String? = nil,
        shoes: String? = nil,
        temperature: Double? = nil,
        humidity: Int? = nil,
        windSpeed: Double? = nil,
        skyConditionRaw: String? = nil,
        windLevelRaw: String? = nil,
        feelsLikeRaw: String? = nil,
        humidityLevelRaw: String? = nil,
        difficultyLevelRaw: Int? = nil,
        routeData: Data? = nil,
        activeEnergyBurned: Double? = nil,
        runningVerticalOscillation: Double? = nil,
        runningGroundContactTime: Double? = nil,
        walkingStepLength: Double? = nil,
        restingHeartRate: Double? = nil,
        runningPower: Double? = nil,
        runningStrideLength: Double? = nil,
        heartRateRecoveryOneMinute: Double? = nil,
        startTime: Date,
        endTime: Date
    ) {
        self.id = id
        self.date = date
        self.distance = distance
        self.duration = duration
        self.averagePace = averagePace
        self.averageHeartRate = averageHeartRate
        self.averageCadence = averageCadence
        self.runningStyleRaw = runningStyleRaw
        self.memo = memo
        self.shoes = shoes
        self.temperature = temperature
        self.humidity = humidity
        self.windSpeed = windSpeed
        self.skyConditionRaw = skyConditionRaw
        self.windLevelRaw = windLevelRaw
        self.feelsLikeRaw = feelsLikeRaw
        self.humidityLevelRaw = humidityLevelRaw
        self.difficultyLevelRaw = difficultyLevelRaw
        self.routeData = routeData
        self.activeEnergyBurned = activeEnergyBurned
        self.runningVerticalOscillation = runningVerticalOscillation
        self.runningGroundContactTime = runningGroundContactTime
        self.walkingStepLength = walkingStepLength
        self.restingHeartRate = restingHeartRate
        self.runningPower = runningPower
        self.runningStrideLength = runningStrideLength
        self.heartRateRecoveryOneMinute = heartRateRecoveryOneMinute
        self.startTime = startTime
        self.endTime = endTime

        self.painAreasRawData = PainAreasMapper.encodeRaw(painAreasRaw)
    }
}

// MARK: - Conversion Methods

public extension RunningRecordPersistenceModel {
    /// WeatherKit 자동 조회 수치(기온/습도/풍속)를 도메인 모델로 변환
    private var weatherData: WeatherData? {
        guard
            let temperature,
            let humidity,
            let windSpeed
        else { return nil }

        return WeatherData(
            temperature: temperature,
            humidity: humidity,
            windSpeed: windSpeed
        )
    }

    /// 저장된 신발 문자열을 카탈로그 `Shoe`와 레거시 문자열로 가른다.
    ///
    /// resolver가 해석하면 `shoe`, 못 하면 원본을 가공 없이 `legacyShoe`에 담는다.
    /// 둘은 상호배타적이며, 원본을 그대로 보존해야 저장 왕복이 무손실이고
    /// `ShoeIdMigrator`가 카탈로그 id를 찾을 매칭 키도 남는다.
    private func splitShoe(using resolver: (String) -> Shoe?) -> (shoe: Shoe?, legacy: String?) {
        guard let shoes, !shoes.isEmpty else { return (nil, nil) }

        guard let resolved = resolver(shoes) else { return (nil, shoes) }

        return (resolved, nil)
    }

    /// - Parameter shoeResolver: 저장된 신발 id를 카탈로그 `Shoe` 엔티티로 복원한다.
    ///   신발 마스터 데이터는 영속 계층이 아닌 원격/캐시에 있으므로 외부에서 주입받는다.
    ///   해석에 실패한 값은 `Diary.legacyShoe`로 넘어간다.
    func toDomain(shoeResolver: (String) -> Shoe? = { _ in nil }) -> Diary {
        // Convert raw values to enums
        let painAreas = PainAreasMapper.decode(painAreasRawData)
        let runningStyle = runningStyleRaw.flatMap { RunninStyle(rawValue: $0) }
        let difficultyLevel = difficultyLevelRaw.flatMap { DifficultyLevel(rawValue: $0) }
        let shoe = splitShoe(using: shoeResolver)

        return Diary(
            id: id,
            workout: HealthKitWorkout(
                distance: distance,
                duration: duration,
                // 저장된 표시 문자열을 역파싱하지 않고 duration·distance로 재계산한다.
                // 두 값 모두 영속되므로 손실 없이 복원되며 원본 대비 오차는 최대 ±1초다.
                averagePaceSecondsPerKm: PaceMapper.secondsPerKm(
                    fromDurationSec: duration,
                    distanceKm: distance
                ),
                averageHeartRate: averageHeartRate,
                averageCadence: averageCadence,
                activeEnergyBurned: activeEnergyBurned ?? 0,
                averageVerticalOscillation: runningVerticalOscillation ?? 0,
                averageGroundContactTime: runningGroundContactTime ?? 0,
                averageStepLength: walkingStepLength ?? 0,
                restingHeartRate: restingHeartRate ?? 0,
                averagePower: runningPower ?? 0,
                averageStrideLength: runningStrideLength ?? 0,
                heartRateRecoveryOneMinute: heartRateRecoveryOneMinute ?? 0,
                route: RouteDataMapper.decode(routeData),
                startDate: startTime,
                endDate: endTime
            ),
            painAreas: painAreas,
            runningStyle: runningStyle,
            memo: memo,
            shoe: shoe.shoe,
            legacyShoe: shoe.legacy,
            weather: weatherData,
            difficultyLevel: difficultyLevel
        )
    }

    static func fromDomain(_ record: Diary) -> RunningRecordPersistenceModel {
        RunningRecordPersistenceModel(
            id: record.id,
            date: record.workout.yearMonthDay.toDate(),
            distance: record.workout.distance,
            duration: record.workout.duration,
            averagePace: record.workout.formattedAveragePace,
            averageHeartRate: record.workout.averageHeartRate,
            averageCadence: record.workout.averageCadence,
            painAreasRaw: record.painAreas.map { $0.rawValue },
            runningStyleRaw: record.runningStyle?.rawValue,
            memo: record.memo,
            shoes: record.shoe?.id ?? record.legacyShoe,
            temperature: record.weather?.temperature,
            humidity: record.weather?.humidity,
            windSpeed: record.weather?.windSpeed,
            difficultyLevelRaw: record.difficultyLevel?.rawValue,
            routeData: RouteDataMapper.encode(record.workout.route),
            activeEnergyBurned: record.workout.activeEnergyBurned,
            runningVerticalOscillation: record.workout.averageVerticalOscillation,
            runningGroundContactTime: record.workout.averageGroundContactTime,
            walkingStepLength: record.workout.averageStepLength,
            restingHeartRate: record.workout.restingHeartRate,
            runningPower: record.workout.averagePower,
            runningStrideLength: record.workout.averageStrideLength,
            heartRateRecoveryOneMinute: record.workout.heartRateRecoveryOneMinute,
            startTime: record.workout.startTime,
            endTime: record.workout.endTime
        )
    }
}

// MARK: - Preview

public extension RunningRecordPersistenceModel {
    private static func date(
        calendar: Calendar = Calendar.current,
        timeZone: TimeZone = TimeZone(identifier: "Asia/Seoul")!,
        year: Int, month: Int, day: Int
    ) -> Date {
        let dateComponent = DateComponents(
            calendar: calendar, timeZone: timeZone, year: year, month: month, day: day)
        let date = calendar.date(from: dateComponent)
        return date ?? Date.now
    }

    static var preview: RunningRecordPersistenceModel {
        RunningRecordPersistenceModel(
            id: UUID(),
            distance: 5.32,
            duration: 1800,
            averagePace: "5'40\"",
            averageHeartRate: 148,
            averageCadence: 172,
            painAreasRaw: ["무릎", "종아리"],
            runningStyleRaw: "Midfoot",
            memo: "상쾌한 아침 러닝이었음. 후반부에 약간 무릎 통증.",
            shoes: "nike-zoom-fly-5",
            temperature: 18.5,
            humidity: 62,
            windSpeed: 3.2,
            skyConditionRaw: "sunny",
            windLevelRaw: "moderate",
            feelsLikeRaw: "neutral",
            humidityLevelRaw: "humid",
            difficultyLevelRaw: 4,
            routeData: nil,
            activeEnergyBurned: 450.0,
            runningVerticalOscillation: 8.2,
            runningGroundContactTime: 240.0,
            walkingStepLength: 1.1,
            startTime: .now,
            endTime: Calendar.current.date(byAdding: .second, value: 1800, to: .now)!
        )
    }

    static var previewRecords: [RunningRecordPersistenceModel] {
        [
            RunningRecordPersistenceModel(
                id: UUID(),
                date: date(year: 2025, month: 10, day: 15),
                distance: 5.0,
                duration: 1780,
                averagePace: "5'55\"",
                averageHeartRate: 152,
                averageCadence: 170,
                painAreasRaw: ["발목"],
                runningStyleRaw: "Forefoot",
                memo: "기온이 약간 높았지만 페이스 유지에 성공.",
                shoes: "asics-metaspeed-sky",
                temperature: 21.0,
                humidity: 58,
                windSpeed: 2.1,
                difficultyLevelRaw: 4,
                routeData: nil,
                activeEnergyBurned: 380.0,
                runningVerticalOscillation: 8.0,
                runningGroundContactTime: 235.0,
                walkingStepLength: 1.0,
                startTime: date(year: 2025, month: 10, day: 15),
                endTime: Calendar.current.date(
                    byAdding: .second, value: 1780, to: date(year: 2025, month: 10, day: 15))!
            ),
            RunningRecordPersistenceModel(
                id: UUID(),
                date: date(year: 2025, month: 10, day: 18),
                distance: 7.8,
                duration: 2600,
                averagePace: "5'20\"",
                averageHeartRate: 155,
                averageCadence: 176,
                painAreasRaw: [],
                runningStyleRaw: "Midfoot",
                memo: "페이스 좋았음. 마지막 1km에서 스퍼트.",
                shoes: "nike-pegasus-40",
                temperature: 17.2,
                humidity: 65,
                windSpeed: 3.4,
                difficultyLevelRaw: 5,
                routeData: nil,
                activeEnergyBurned: 620.0,
                runningVerticalOscillation: 8.5,
                runningGroundContactTime: 230.0,
                walkingStepLength: 1.2,
                startTime: date(year: 2025, month: 10, day: 18),
                endTime: Calendar.current.date(
                    byAdding: .second, value: 2600, to: date(year: 2025, month: 10, day: 18))!
            ),
            RunningRecordPersistenceModel(
                id: UUID(),
                distance: 3.5,
                duration: 1200,
                averagePace: "5'45\"",
                averageHeartRate: 140,
                averageCadence: 168,
                painAreasRaw: ["허벅지"],
                runningStyleRaw: "Rearfoot",
                memo: "전날 술 때문에 컨디션이 안 좋았음.",
                shoes: "adidas-adizero-boston-12",
                temperature: 19.5,
                humidity: 70,
                windSpeed: 2.8,
                difficultyLevelRaw: 2,
                routeData: nil,
                activeEnergyBurned: 280.0,
                runningVerticalOscillation: 7.5,
                runningGroundContactTime: 250.0,
                walkingStepLength: 0.95,
                startTime: .now,
                endTime: Calendar.current.date(byAdding: .second, value: 1200, to: .now)!
            ),
            RunningRecordPersistenceModel.preview,
            RunningRecordPersistenceModel(
                id: UUID(),
                distance: 10.0,
                duration: 3600,
                averagePace: "6'00\"",
                averageHeartRate: 150,
                averageCadence: 165,
                painAreasRaw: [],
                runningStyleRaw: nil,
                memo: nil,
                shoes: nil,
                temperature: nil,
                humidity: nil,
                windSpeed: nil,
                difficultyLevelRaw: nil,
                routeData: nil,
                activeEnergyBurned: nil,
                runningVerticalOscillation: nil,
                runningGroundContactTime: nil,
                walkingStepLength: nil,
                startTime: date(year: 2025, month: 11, day: 1),
                endTime: Calendar.current.date(byAdding: .second, value: 3600, to: date(year: 2025, month: 11, day: 1))!
            ),
        ]
    }
}
