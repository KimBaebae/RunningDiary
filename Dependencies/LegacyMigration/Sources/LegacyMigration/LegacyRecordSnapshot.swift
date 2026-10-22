import Foundation

/// SwiftData 스키마를 변경하지 않고 영속 필드 전체를 복사하는 전송 값.
public struct LegacyRecordSnapshot: Codable, Equatable, Sendable {
    public var id: UUID
    public var date: Double
    public var distance: Double
    public var duration: Double
    public var averagePace: String
    public var averageHeartRate: Int
    public var averageCadence: Int
    public var painAreasRawData: String?
    public var runningStyleRaw: String?
    public var memo: String?
    public var shoes: String?
    public var temperature: Double?
    public var humidity: Int?
    public var windSpeed: Double?
    public var skyConditionRaw: String?
    public var windLevelRaw: String?
    public var feelsLikeRaw: String?
    public var humidityLevelRaw: String?
    public var difficultyLevelRaw: Int?
    public var routeData: Data?
    public var activeEnergyBurned: Double?
    public var runningVerticalOscillation: Double?
    public var runningGroundContactTime: Double?
    public var walkingStepLength: Double?
    public var restingHeartRate: Double?
    public var runningPower: Double?
    public var runningStrideLength: Double?
    public var heartRateRecoveryOneMinute: Double?
    public var startTime: Double
    public var endTime: Double

    public init(
        id: UUID,
        date: Double,
        distance: Double,
        duration: Double,
        averagePace: String,
        averageHeartRate: Int,
        averageCadence: Int,
        painAreasRawData: String? = nil,
        runningStyleRaw: String? = nil,
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
        startTime: Double,
        endTime: Double
    ) {
        self.id = id
        self.date = date
        self.distance = distance
        self.duration = duration
        self.averagePace = averagePace
        self.averageHeartRate = averageHeartRate
        self.averageCadence = averageCadence
        self.painAreasRawData = painAreasRawData
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
    }

    public func json() throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return String(decoding: try encoder.encode(self), as: UTF8.self)
    }
}
