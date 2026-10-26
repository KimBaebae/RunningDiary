//
//  RoutePoint.swift
//  Models
//
//  Created by 김혜지 on 7/30/26.
//

import Foundation

/// 달리기 경로의 단일 지점. 위경도에 고도와 워크아웃 시작 후 경과초를 함께 보유해
/// 경로 렌더링과 시간축 고도 시계열을 한 배열로 커버한다.
///
/// `altitude`·`elapsedSec`는 옵셔널이며, 합성 `Decodable`이 옵셔널 프로퍼티를
/// `decodeIfPresent`로 처리하므로 두 필드가 없는 레거시 JSON(`{latitude, longitude}`)도
/// 그대로 디코딩된다. 기존에 저장된 경로를 읽기 위한 계약이므로 두 필드를 non-optional로
/// 바꾸면 안 된다. (`RoutePointTests`가 이 호환성을 고정한다)
public struct RoutePoint: Equatable, Sendable, Codable {
    public let latitude: Double
    public let longitude: Double
    public let altitude: Double?            // 고도 (m). 레거시 저장분·미측정 시 nil
    public let elapsedSec: TimeInterval?    // 워크아웃 시작 후 경과 초. 레거시 저장분은 nil

    public init(
        latitude: Double,
        longitude: Double,
        altitude: Double? = nil,
        elapsedSec: TimeInterval? = nil
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.elapsedSec = elapsedSec
    }
}
