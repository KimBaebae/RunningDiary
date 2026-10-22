//
//  RoutePointRequest.swift
//  Models
//
//  Created by Claude on 9/8/26.
//

/// `workout.route` 배열 원소.
///
/// 엔티티 `RoutePoint`를 재사용하지 않는다. 합성 `Encodable`은 옵셔널 프로퍼티(`altitude`,
/// `elapsedSec`)를 `encodeIfPresent`로 처리해 값이 없으면 키 자체를 지우는데, 계약 문서는
/// 두 필드를 `Number | null`로 규정해 키 존재를 전제하므로 커스텀 `encode(to:)`가 필요하다.
public struct RoutePointRequest: Encodable, Equatable, Sendable {
    public let latitude: Double
    public let longitude: Double
    public let altitude: Double?
    public let elapsedSec: Double?

    public init(
        latitude: Double,
        longitude: Double,
        altitude: Double?,
        elapsedSec: Double?
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.elapsedSec = elapsedSec
    }

    private enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
        case altitude
        case elapsedSec
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        try container.encode(altitude, forKey: .altitude)
        try container.encode(elapsedSec, forKey: .elapsedSec)
    }
}
