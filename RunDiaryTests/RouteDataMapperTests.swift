//
//  RouteDataMapperTests.swift
//  RunDiaryTests
//
//  Models 스킴에는 test action이 없어 ModelsTests가 실행되지 않는다.
//  실제로 도는 이 타겟으로 옮겼다. (RouteDownsamplerTests와 같은 이유)

import Foundation
import Models
import Testing

@Suite("RouteDataMapper")
struct RouteDataMapperTests {

    // MARK: - encode

    @Test("경로가 nil이면 인코딩 결과도 nil이다")
    func encode_isNil_whenRouteIsNil() {
        // When
        let result = RouteDataMapper.encode(nil)

        // Then
        #expect(result == nil)
    }

    @Test("빈 경로를 인코딩하면 nil을 반환한다")
    func encode_isNil_whenRouteIsEmpty() {
        // When
        let result = RouteDataMapper.encode([])

        // Then
        #expect(result == nil)
    }

    // MARK: - 왕복

    @Test("인코딩 후 디코딩하면 좌표·고도·경과초가 보존된다")
    func encodeDecode_preservesRoute() {
        // Given
        let expected = [
            RoutePoint(latitude: 37.5665, longitude: 126.9780, altitude: 12.4, elapsedSec: 0),
            RoutePoint(latitude: 37.5668, longitude: 126.9783, altitude: 13.1, elapsedSec: 5),
        ]

        // When
        let data = RouteDataMapper.encode(expected)
        let result = RouteDataMapper.decode(data)

        // Then
        #expect(result == expected)
    }

    @Test("경로 없음은 왕복해도 빈 배열이 아니라 nil로 유지된다")
    func encodeDecode_keepsNil_whenRouteIsAbsent() {
        // When
        let result = RouteDataMapper.decode(RouteDataMapper.encode(nil))

        // Then
        #expect(result == nil)
    }

    // MARK: - decode

    @Test("nil Data를 디코딩하면 nil을 반환한다")
    func decode_isNil_whenDataIsNil() {
        // When
        let result = RouteDataMapper.decode(nil)

        // Then
        #expect(result == nil)
    }

    @Test("잘못된 Data를 디코딩하면 nil을 반환한다")
    func decode_isNil_whenDataIsInvalid() {
        // Given
        let invalidData = Data("not json".utf8)

        // When
        let result = RouteDataMapper.decode(invalidData)

        // Then
        #expect(result == nil)
    }

    @Test("빈 배열이 저장돼 있어도 경로 없음으로 보고 nil을 반환한다")
    func decode_isNil_whenStoredArrayIsEmpty() {
        // Given
        let emptyArrayData = Data("[]".utf8)

        // When
        let result = RouteDataMapper.decode(emptyArrayData)

        // Then
        #expect(result == nil)
    }

    @Test("레거시 위경도 전용 Data도 디코딩된다")
    func decode_supportsLegacyLocationData() {
        // Given
        let expectedCount = 2
        let legacyData = Data(
            #"[{"latitude":37.5665,"longitude":126.978},{"latitude":37.5668,"longitude":126.9783}]"#.utf8
        )

        // When
        let result = RouteDataMapper.decode(legacyData)

        // Then
        #expect(result?.count == expectedCount)
        #expect(result?.allSatisfy { $0.altitude == nil } == true)
    }
}
