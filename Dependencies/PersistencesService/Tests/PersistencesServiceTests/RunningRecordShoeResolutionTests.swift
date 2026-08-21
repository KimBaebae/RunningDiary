//
//  RunningRecordShoeResolutionTests.swift
//  PersistencesServiceTests
//
//  Created by 김혜지 on 8/3/26.
//

import Foundation
import Models
import Testing

@testable import PersistencesService

/// 저장 컬럼은 `shoes` 하나뿐이고, 카탈로그 해석 성공 여부로 `shoe`와 `legacyShoe`가 갈린다.
@Suite("RunningRecordPersistenceModel 신발 복원")
struct RunningRecordShoeResolutionTests {

    @Test("resolver가 해석하면 shoe에 담기고 legacyShoe는 비어 있다")
    func toDomain_fillsShoe_whenResolverResolves() {
        // Given
        let catalogShoe = makeCatalogShoe(id: "68f0a1b2c3d4e5f601234567")
        let model = RunningRecordPersistenceModel.fromDomain(makeDiary(shoe: catalogShoe))

        // When
        let restored = model.toDomain { $0 == catalogShoe.id ? catalogShoe : nil }

        // Then
        #expect(restored.shoe == catalogShoe)
        #expect(restored.legacyShoe == nil)
    }

    @Test("resolver가 해석하지 못하면 저장 원본이 legacyShoe로 남고 shoe는 비어 있다")
    func toDomain_fillsLegacyShoe_whenResolverFails() {
        // Given
        let expectedLegacyShoe = "nike-alphafly-3"
        let model = RunningRecordPersistenceModel.fromDomain(makeDiary(legacyShoe: expectedLegacyShoe))

        // When
        let restored = model.toDomain { _ in nil }

        // Then
        #expect(restored.shoe == nil)
        #expect(restored.legacyShoe == expectedLegacyShoe)
    }

    @Test("신발이 없으면 shoe와 legacyShoe 모두 비어 있다")
    func toDomain_leavesBothNil_whenNoShoeStored() {
        // Given
        let model = RunningRecordPersistenceModel.fromDomain(makeDiary())

        // When
        let restored = model.toDomain { _ in nil }

        // Then
        #expect(restored.shoe == nil)
        #expect(restored.legacyShoe == nil)
    }

    @Test("legacyShoe 원본 문자열은 저장 왕복에서 가공 없이 보존된다")
    func fromDomain_preservesLegacyShoe_throughRoundTrip() {
        // Given
        let expectedLegacyShoe = "nike-alphafly-3"
        let restored = RunningRecordPersistenceModel
            .fromDomain(makeDiary(legacyShoe: expectedLegacyShoe))
            .toDomain { _ in nil }

        // When - 복원한 일지를 다시 저장한다
        let model = RunningRecordPersistenceModel.fromDomain(restored)

        // Then
        #expect(model.shoes == expectedLegacyShoe)
    }

    @Test("카탈로그 신발은 저장 시 Shoe.id로 기록된다")
    func fromDomain_storesCatalogId_whenShoeResolved() {
        // Given
        let catalogShoe = makeCatalogShoe(id: "68f0a1b2c3d4e5f601234568")

        // When
        let model = RunningRecordPersistenceModel.fromDomain(makeDiary(shoe: catalogShoe))

        // Then
        #expect(model.shoes == catalogShoe.id)
    }
}

// MARK: - Helper

private extension RunningRecordShoeResolutionTests {
    func makeDiary(shoe: Shoe? = nil, legacyShoe: String? = nil) -> Diary {
        let startDate = Date(timeIntervalSince1970: 1_752_300_000)

        return Diary(
            workout: HealthKitWorkout(
                distance: 7.42,
                duration: 2_550,
                averagePaceSecondsPerKm: 344,
                averageHeartRate: 152,
                averageCadence: 174,
                activeEnergyBurned: 512,
                averageVerticalOscillation: 8.4,
                averageGroundContactTime: 236,
                averageStepLength: 1.12,
                restingHeartRate: 58,
                averagePower: 310,
                averageStrideLength: 1.35,
                heartRateRecoveryOneMinute: 32,
                startDate: startDate,
                endDate: startDate.addingTimeInterval(2_570)
            ),
            runningStyle: .midfoot,
            shoe: shoe,
            legacyShoe: legacyShoe
        )
    }

    func makeCatalogShoe(id: String) -> Shoe {
        Shoe(
            id: id,
            brandName: "Nike",
            name: "Alphafly 3",
            nameKo: "알파플라이 3",
            category: [:],
            subcategory: [:],
            tags: [],
            imageUrl: nil,
            reviewSummary: nil,
            pros: [],
            cons: [],
            description: nil
        )
    }
}
