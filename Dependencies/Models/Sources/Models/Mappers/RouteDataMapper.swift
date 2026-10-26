//
//  RouteDataMapper.swift
//  Models
//
//  Created by 김혜지 on 7/30/26.
//

import Foundation

/// `[RoutePoint]?`와 영속 계층의 JSON `Data?` 사이를 변환한다.
/// 도메인은 경로를 옵셔널로 다루고 `Data` 표현은 저장 시점에만 존재한다.
///
/// 양쪽 모두 "경로 없음"을 `nil`로 표현한다. 빈 배열은 만들지 않는다.
public enum RouteDataMapper {
    /// 경로를 JSON Data로 인코딩한다. 경로가 없거나 비어 있으면 nil을 반환한다.
    public static func encode(_ route: [RoutePoint]?) -> Data? {
        guard let route, !route.isEmpty else { return nil }

        return try? JSONEncoder().encode(route)
    }

    /// JSON Data를 경로로 디코딩한다. 데이터가 없거나 디코딩에 실패하거나 결과가 비면 nil을 반환한다.
    /// 고도·경과초가 없는 레거시 포맷도 `RoutePoint`의 옵셔널 필드로 흡수된다.
    public static func decode(_ data: Data?) -> [RoutePoint]? {
        guard
            let data,
            let route = try? JSONDecoder().decode([RoutePoint].self, from: data),
            !route.isEmpty
        else { return nil }

        return route
    }
}
