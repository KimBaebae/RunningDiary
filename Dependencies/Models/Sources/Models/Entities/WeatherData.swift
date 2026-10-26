//
//  WeatherData.swift
//  Models
//
//  Created by 김혜지 on 10/31/25.
//

public struct WeatherData: Equatable, Sendable {
    public let temperature: Double  // 기온 (°C)
    public let humidity: Int        // 습도 (%)
    public let windSpeed: Double    // 풍속 (m/s)

    // WeatherKit 원시 수치. 등급 분류는 서버가 재계산하므로 값만 그대로 보존한다.
    // 옵셔널인 이유 둘:
    // 1. WeatherKit 응답 자체에 값이 없을 수 있다.
    // 2. SwiftData에 대응 컬럼이 없어 로컬 복원분은 항상 nil이다.
    //    날씨는 일지 생성 시점에 조회해 그 자리에서 전송하는 것이 정상 경로다.
    public let apparentTemperature: Double?   // 체감온도 (°C)
    public let cloudCover: Double?            // 구름량 (0.0~1.0)
    public let precipitationAmount: Double?   // 강수량 (mm)

    public init(
        temperature: Double,
        humidity: Int,
        windSpeed: Double,
        apparentTemperature: Double? = nil,
        cloudCover: Double? = nil,
        precipitationAmount: Double? = nil
    ) {
        self.temperature = temperature
        self.humidity = humidity
        self.windSpeed = windSpeed
        self.apparentTemperature = apparentTemperature
        self.cloudCover = cloudCover
        self.precipitationAmount = precipitationAmount
    }
}
