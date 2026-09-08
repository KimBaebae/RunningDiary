//
//  WorkoutTimeZoneResolverTests.swift
//  HealthKitServiceTests
//
//  Created by 김혜지 on 8/3/26.
//

import Foundation
import Testing

@testable import HealthKitService

@Suite("WorkoutTimeZoneResolver.resolve")
struct WorkoutTimeZoneResolverTests {

    @Test("메타데이터에 IANA identifier가 있으면 해당 타임존을 사용한다")
    func resolve_returnsMetadataTimeZone_whenIdentifierIsValid() {
        // Given
        let identifier = "Asia/Seoul"
        let expectedTimeZone = TimeZone(identifier: identifier)

        // When
        let result = WorkoutTimeZoneResolver.resolve(identifier: identifier)

        // Then
        #expect(result == expectedTimeZone)
    }

    @Test("해외에서 기록한 워크아웃은 기기 현재 타임존이 아니라 기록 당시 타임존을 사용한다")
    func resolve_returnsRecordedTimeZone_whenDifferentFromCurrent() {
        // Given
        let identifier = "America/Los_Angeles"
        let expectedTimeZone = TimeZone(identifier: identifier)

        // When
        let result = WorkoutTimeZoneResolver.resolve(identifier: identifier)

        // Then
        #expect(result == expectedTimeZone)
        #expect(result?.identifier == identifier)
    }

    @Test("메타데이터가 없으면 nil을 반환한다")
    func resolve_returnsNil_whenIdentifierIsNil() {
        // Given
        let expectedTimeZone: TimeZone? = nil

        // When
        let result = WorkoutTimeZoneResolver.resolve(identifier: nil)

        // Then
        #expect(result == expectedTimeZone)
    }

    @Test("알 수 없는 identifier면 nil을 반환한다")
    func resolve_returnsNil_whenIdentifierIsUnknown() {
        // Given
        let expectedTimeZone: TimeZone? = nil

        // When
        let result = WorkoutTimeZoneResolver.resolve(identifier: "Not/AZone")

        // Then
        #expect(result == expectedTimeZone)
    }
}
