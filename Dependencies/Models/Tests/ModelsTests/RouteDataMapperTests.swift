import Foundation
@testable import Models
import Testing

@Suite("RouteDataMapper")
struct RouteDataMapperTests {

    @Test("빈 경로를 인코딩하면 nil을 반환한다")
    func encode_isNil_whenRouteIsEmpty() {
        // When
        let result = RouteDataMapper.encode([])

        // Then
        #expect(result == nil)
    }

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

    @Test("nil Data를 디코딩하면 빈 배열을 반환한다")
    func decode_isEmpty_whenDataIsNil() {
        // When
        let result = RouteDataMapper.decode(nil)

        // Then
        #expect(result.isEmpty)
    }

    @Test("잘못된 Data를 디코딩하면 빈 배열을 반환한다")
    func decode_isEmpty_whenDataIsInvalid() {
        // Given
        let invalidData = Data("not json".utf8)

        // When
        let result = RouteDataMapper.decode(invalidData)

        // Then
        #expect(result.isEmpty)
    }

    @Test("레거시 위경도 전용 Data도 디코딩된다")
    func decode_supportsLegacyLocationData() {
        // Given
        let expectedCount = 2
        let legacyData = Data(#"[{"latitude":37.5665,"longitude":126.978},{"latitude":37.5668,"longitude":126.9783}]"#.utf8)

        // When
        let result = RouteDataMapper.decode(legacyData)

        // Then
        #expect(result.count == expectedCount)
        #expect(result.allSatisfy { $0.altitude == nil })
    }
}
