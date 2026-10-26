//
//  ShoeIdMigratorTests.swift
//  RunDiaryTests
//
//  Created by 김혜지 on 8/3/26.
//

import Foundation
import Models
import Testing

@testable import RunDiary

@Suite("ShoeIdMigrator.resolve")
struct ShoeIdMigratorResolveTests {

    @Test("레거시 슬러그는 표시 이름이 일치하는 카탈로그 항목으로 해석된다")
    func resolve_matchesByDecodedName_whenLegacySlug() {
        // Given
        let expectedId = "68f0a1b2c3d4e5f601234567"
        let catalog = [
            makeCatalogShoe(id: expectedId, brand: "Nike", name: "Alphafly 3"),
            makeCatalogShoe(id: "68f0a1b2c3d4e5f60123456f", brand: "Hoka", name: "Mach 6"),
        ]

        // When
        let result = ShoeIdMigrator.resolve(legacyShoe: "nike-alphafly-3", in: catalog)

        // Then
        #expect(result?.id == expectedId)
    }

    @Test("카탈로그 이름이 브랜드를 포함해도 해석된다")
    func resolve_matchesByDecodedName_whenCatalogNameIncludesBrand() {
        // Given
        let expectedId = "68f0a1b2c3d4e5f601234568"
        let catalog = [makeCatalogShoe(id: expectedId, brand: "Nike", name: "Nike Alphafly 3")]

        // When
        let result = ShoeIdMigrator.resolve(legacyShoe: "nike-alphafly-3", in: catalog)

        // Then
        #expect(result?.id == expectedId)
    }

    @Test("카탈로그 로드 전에 legacyShoe로 떨어진 정상 id는 완전 일치로 해석된다")
    func resolve_matchesById_whenValueIsCatalogId() {
        // Given
        let expectedId = "68f0a1b2c3d4e5f601234569"
        let catalog = [makeCatalogShoe(id: expectedId, brand: "Asics", name: "Novablast 5")]

        // When
        let result = ShoeIdMigrator.resolve(legacyShoe: expectedId, in: catalog)

        // Then
        #expect(result?.id == expectedId)
    }

    @Test("카탈로그에 없는 신발은 해석하지 않는다")
    func resolve_returnsNil_whenNoMatch() {
        // Given
        let catalog = [makeCatalogShoe(id: "68f0a1b2c3d4e5f60123456a", brand: "Hoka", name: "Mach 6")]

        // When
        let result = ShoeIdMigrator.resolve(legacyShoe: "nike-alphafly-3", in: catalog)

        // Then
        #expect(result == nil)
    }

    @Test("빈 문자열은 해석하지 않는다")
    func resolve_returnsNil_whenLegacyShoeIsEmpty() {
        // Given
        let catalog = [makeCatalogShoe(id: "68f0a1b2c3d4e5f60123456b", brand: "Nike", name: "Alphafly 3")]

        // When
        let result = ShoeIdMigrator.resolve(legacyShoe: "", in: catalog)

        // Then
        #expect(result == nil)
    }

    @Test("카탈로그 순서가 달라도 같은 결과를 반환한다")
    func resolve_isDeterministic_whenCatalogOrderDiffers() {
        // Given
        let catalog = [
            makeCatalogShoe(id: "68f0a1b2c3d4e5f60123456c", brand: "Nike", name: "Alphafly 3"),
            makeCatalogShoe(id: "68f0a1b2c3d4e5f60123456d", brand: "Hoka", name: "Mach 6"),
        ]

        // When
        let forward = ShoeIdMigrator.resolve(legacyShoe: "hoka-mach-6", in: catalog)
        let reversed = ShoeIdMigrator.resolve(legacyShoe: "hoka-mach-6", in: catalog.reversed())

        // Then
        #expect(forward?.id == reversed?.id)
    }
}

@Suite("ShoeIdMigrator.migrate")
struct ShoeIdMigratorMigrateTests {

    @Test("레거시 신발을 가진 일지만 카탈로그 id로 매핑된다")
    func migrate_mapsOnlyResolvableLegacyRecords() {
        // Given
        let expectedId = "68f0a1b2c3d4e5f60123456e"
        let catalog = [makeCatalogShoe(id: expectedId, brand: "Nike", name: "Alphafly 3")]
        let migratable = Diary(
            workout: makeWorkout(),
            runningStyle: .midfoot,
            legacyShoe: "nike-alphafly-3"
        )
        let unmatched = Diary(
            workout: makeWorkout(),
            runningStyle: .midfoot,
            legacyShoe: "unknown-shoe"
        )
        let alreadyResolved = Diary(
            workout: makeWorkout(),
            runningStyle: .midfoot,
            shoe: catalog[0]
        )

        // When
        let result = ShoeIdMigrator.migrate(
            records: [migratable, unmatched, alreadyResolved],
            catalog: catalog
        )

        // Then
        #expect(result == [migratable.id: expectedId])
    }

    @Test("카탈로그가 비어 있으면 아무것도 매핑하지 않는다")
    func migrate_returnsEmpty_whenCatalogIsEmpty() {
        // Given
        let record = Diary(
            workout: makeWorkout(),
            runningStyle: .midfoot,
            legacyShoe: "nike-alphafly-3"
        )

        // When
        let result = ShoeIdMigrator.migrate(records: [record], catalog: [])

        // Then
        #expect(result.isEmpty)
    }
}

// MARK: - Helper

private func makeCatalogShoe(id: String, brand: String, name: String) -> Shoe {
    Shoe(
        id: id,
        brandName: brand,
        name: name,
        nameKo: name,
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
