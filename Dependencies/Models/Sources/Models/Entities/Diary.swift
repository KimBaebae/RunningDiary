//
//  Diary.swift
//  Models
//
//  Created by 김혜지 on 9/23/25.
//

import Foundation

/// 하루치 러닝 일지.
///
/// 신발은 `shoe`와 `legacyShoe` 중 한쪽만 채워진다.
/// 저장된 신발 문자열이 서버 카탈로그로 해석되면 `shoe`, 해석되지 않으면 `legacyShoe`다.
/// 서버 전송 계약은 카탈로그 `Shoe.id`만 취급하므로 `legacyShoe`는 로컬 전용이며,
/// `ShoeIdMigrator`가 카탈로그 id로 옮기면 소멸한다.
public struct Diary: Identifiable, Equatable, Sendable {
    public let id: UUID                                 // 다이어리 고유 id
    public let workout: HealthKitWorkout
    public let painAreas: [PainArea]                    // 통증 부위
    public let runningStyle: RunninStyle?               // 달리기 스타일
    public let memo: String?                            // 메모
    public let shoe: Shoe?                              // 착용 신발. id는 항상 서버 카탈로그의 `Shoe.id`
    public let legacyShoe: String?                      // 카탈로그로 해석되지 않은 저장 원본 문자열
    public let weather: WeatherData?                    // 날씨 (WeatherKit 자동 조회 수치)
    public let userWeather: UserWeather?                // 유저가 선택한 날씨
    public let difficultyLevel: DifficultyLevel?        // 달리기 난이도

    public init(
        id: UUID = UUID(),
        workout: HealthKitWorkout,
        painAreas: [PainArea] = [],
        runningStyle: RunninStyle?,
        memo: String? = nil,
        shoe: Shoe? = nil,
        legacyShoe: String? = nil,
        weather: WeatherData? = nil,
        userWeather: UserWeather? = nil,
        difficultyLevel: DifficultyLevel? = nil
    ) {
        self.id = id
        self.workout = workout
        self.painAreas = painAreas
        self.runningStyle = runningStyle
        self.memo = memo
        self.shoe = shoe
        self.legacyShoe = legacyShoe
        self.weather = weather
        self.userWeather = userWeather
        self.difficultyLevel = difficultyLevel
    }
}
