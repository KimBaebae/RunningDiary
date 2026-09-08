//
//  WeatherKitManager.swift
//  RunDiary
//
//  Created by Claude on 2025-11-06.
//

import CoreLocation
import Foundation
import Models
import WeatherKit

public final class WeatherKitManager: WeatherManagerProtocol {
    private let weatherService = WeatherService.shared

    public init() {}

    public func fetchWeather(for date: Date, location: CLLocationCoordinate2D?) async throws -> WeatherData {
        guard let location = location else {
            throw WeatherKitError.missingLocation
        }

        let clLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        let queryStart = date.addingTimeInterval(-1800)
        let queryEnd = date.addingTimeInterval(1800)

        // WeatherKit으로 특정 날짜/시간의 날씨 조회
        let hourlyWeather = try await weatherService.weather(
            for: clLocation,
            including: .hourly(startDate: queryStart, endDate: queryEnd)
        )

        guard let weather = hourlyWeather.min(by: {
            abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
        }) else {
            throw WeatherKitError.dataUnavailable
        }

        return WeatherData(
            // NOTE: weather.temperature는 단위 변환 없이 .value를 그대로 쓴다.
            // 계약 단위(°C)와 어긋날 수 있는 기존 동작이지만 이번 작업 범위가 아니라 그대로 둔다.
            temperature: weather.temperature.value,
            humidity: Int(weather.humidity * 100),
            windSpeed: weather.wind.speed.value,
            apparentTemperature: weather.apparentTemperature.converted(to: .celsius).value,
            cloudCover: weather.cloudCover,
            precipitationAmount: weather.precipitationAmount.converted(to: .millimeters).value
        )
    }

    public func fetchTrademark() async throws -> WeatherTrademark {
        let attribution = try await weatherService.attribution
        return WeatherTrademark(
            imageURL: attribution.combinedMarkLightURL,
            legalPageURL: attribution.legalPageURL
        )
    }
}
