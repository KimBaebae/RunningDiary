//
//  ShoeCache.swift
//  RunDiary
//
//  Created by 김혜지 on 4/22/26.
//

import Models

public actor ShoeCache {
    public static let shared = ShoeCache()

    private var flat: [Shoe] = []
    private var grouped: [String: [Shoe]] = [:]
    private var byID: [String: Shoe] = [:]
    private var loaded = false

    private init() {}

    public func store(_ shoes: [Shoe]) {
        let sorted = shoes.sorted { $0.nameKo < $1.nameKo }
        flat = sorted
        grouped = Dictionary(grouping: sorted) { $0.brandName }
            .mapValues { $0.sorted { $0.nameKo < $1.nameKo } }
        byID = Dictionary(uniqueKeysWithValues: sorted.map { ($0.id, $0) })
        loaded = true
    }

    public func allShoes() -> [Shoe] { flat }
    public func groupedShoes() -> [String: [Shoe]] { grouped }
    public func shoes(for brand: String) -> [Shoe] { grouped[brand] ?? [] }
    public func shoe(id: String) -> Shoe? { byID[id] }

    public func displayName(for id: String) -> String? {
        if let shoe = byID[id] { return shoe.nameKo }
        return LegacyShoeMapper.decodeName(from: id)
    }

    /// 현재 캐시 스냅샷을 캡처한 동기 resolver를 만든다.
    /// 영속 계층이 신발 id를 `Shoe`로 복원할 때 사용한다.
    /// 캐시에 없는 id는 레거시 슬러그로 간주해 표시 이름만 복원한다.
    public func makeShoeResolver() -> @Sendable (String) -> Shoe? {
        let snapshot = byID

        return { id in
            if let shoe = snapshot[id] { return shoe }

            guard let name = LegacyShoeMapper.decodeName(from: id) else { return nil }

            return .unresolved(id: id, displayName: name)
        }
    }

    public var isLoaded: Bool { loaded }

    public func reset() {
        flat = []
        grouped = [:]
        byID = [:]
        loaded = false
    }
}
