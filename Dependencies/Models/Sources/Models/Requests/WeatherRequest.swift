//
//  WeatherRequest.swift
//  Models
//
//  Created by Claude on 9/8/26.
//

/// `weather` 객체.
///
/// 옵셔널 필드는 합성 `Encodable`의 `encodeIfPresent` 대신 `encode(to:)`를 직접 구현해
/// `nil`을 키 생략이 아닌 명시적 `null`로 인코딩한다. 계약 문서가 `Number | null`처럼
/// 값의 존재 자체를 스키마로 규정하므로 "키 없음"과 "null"을 섞으면 안 되기 때문이다.
public struct WeatherRequest: Encodable, Equatable, Sendable {
    public let temperature: Double
    public let humidity: Int
    public let windSpeed: Double
    public let apparentTemperature: Double?
    public let cloudCover: Double?
    public let precipitationAmount: Double?

    public init(
        temperature: Double,
        humidity: Int,
        windSpeed: Double,
        apparentTemperature: Double?,
        cloudCover: Double?,
        precipitationAmount: Double?
    ) {
        self.temperature = temperature
        self.humidity = humidity
        self.windSpeed = windSpeed
        self.apparentTemperature = apparentTemperature
        self.cloudCover = cloudCover
        self.precipitationAmount = precipitationAmount
    }

    private enum CodingKeys: String, CodingKey {
        case temperature
        case humidity
        case windSpeed
        case apparentTemperature
        case cloudCover
        case precipitationAmount
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(temperature, forKey: .temperature)
        try container.encode(humidity, forKey: .humidity)
        try container.encode(windSpeed, forKey: .windSpeed)
        try container.encode(apparentTemperature, forKey: .apparentTemperature)
        try container.encode(cloudCover, forKey: .cloudCover)
        try container.encode(precipitationAmount, forKey: .precipitationAmount)
    }
}
