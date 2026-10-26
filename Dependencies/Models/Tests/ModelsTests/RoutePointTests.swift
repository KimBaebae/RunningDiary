import Foundation
@testable import Models
import Testing

@Suite("RoutePoint 디코딩")
struct RoutePointTests {

    @Test("레거시 [Location] JSON은 altitude·elapsedSec가 nil인 RoutePoint로 디코딩된다")
    func decode_legacyJSON_fillsOptionalsWithNil() throws {
        // Given
        let expectedLatitude = 37.5665
        let expectedLongitude = 126.9780
        let json = #"[{"latitude":37.5665,"longitude":126.9780}]"#
        let data = Data(json.utf8)

        // When
        let points = try JSONDecoder().decode([RoutePoint].self, from: data)

        // Then
        #expect(points.count == 1)
        #expect(points.first?.latitude == expectedLatitude)
        #expect(points.first?.longitude == expectedLongitude)
        #expect(points.first?.altitude == nil)
        #expect(points.first?.elapsedSec == nil)
    }

    @Test("신규 포맷은 4개 필드가 모두 복원된다")
    func decode_newFormat_restoresAllFields() throws {
        // Given
        let expectedAltitude = 12.4
        let expectedElapsedSec: TimeInterval = 30
        let json = #"[{"latitude":37.5665,"longitude":126.9780,"altitude":12.4,"elapsedSec":30}]"#
        let data = Data(json.utf8)

        // When
        let points = try JSONDecoder().decode([RoutePoint].self, from: data)

        // Then
        #expect(points.first?.altitude == expectedAltitude)
        #expect(points.first?.elapsedSec == expectedElapsedSec)
    }

    @Test("인코딩 후 디코딩하면 모든 필드가 보존된다")
    func encodeDecode_preservesAllFields() throws {
        // Given
        let expected = RoutePoint(latitude: 37.5665, longitude: 126.9780, altitude: 12.4, elapsedSec: 30)

        // When
        let data = try JSONEncoder().encode([expected])
        let points = try JSONDecoder().decode([RoutePoint].self, from: data)

        // Then
        #expect(points == [expected])
    }
}
