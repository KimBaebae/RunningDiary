//
//  CreateDiaryRequest.swift
//  Models
//
//  Created by Claude on 9/8/26.
//

/// `POST /api/v1/running-logs` 요청 바디 최상위 객체.
///
/// 옵셔널 필드는 합성 `Encodable`의 `encodeIfPresent` 대신 `encode(to:)`를 직접 구현해
/// `nil`을 키 생략이 아닌 명시적 `null`로 인코딩한다. 계약 문서가 `String | null`처럼
/// 값의 존재 자체를 스키마로 규정하므로 "키 없음"과 "null"을 섞으면 안 되기 때문이다.
public struct CreateDiaryRequest: Encodable, Equatable, Sendable {
    public let workout: WorkoutRequest
    public let weather: WeatherRequest?
    public let painAreas: [String]
    public let runningStyle: String?
    public let memo: String?
    public let shoeId: String?
    public let difficultyLevel: Int?

    public init(
        workout: WorkoutRequest,
        weather: WeatherRequest?,
        painAreas: [String],
        runningStyle: String?,
        memo: String?,
        shoeId: String?,
        difficultyLevel: Int?
    ) {
        self.workout = workout
        self.weather = weather
        self.painAreas = painAreas
        self.runningStyle = runningStyle
        self.memo = memo
        self.shoeId = shoeId
        self.difficultyLevel = difficultyLevel
    }

    private enum CodingKeys: String, CodingKey {
        case workout
        case weather
        case painAreas
        case runningStyle
        case memo
        case shoeId
        case difficultyLevel
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(workout, forKey: .workout)
        try container.encode(weather, forKey: .weather)
        try container.encode(painAreas, forKey: .painAreas)
        try container.encode(runningStyle, forKey: .runningStyle)
        try container.encode(memo, forKey: .memo)
        try container.encode(shoeId, forKey: .shoeId)
        try container.encode(difficultyLevel, forKey: .difficultyLevel)
    }
}
