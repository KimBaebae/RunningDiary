//
//  ShoeIdMigrator.swift
//  RunDiary
//
//  Created by 김혜지 on 8/3/26.
//

import Foundation
import Models

// 카탈로그로 해석되지 않은 저장 신발 문자열(`Diary.legacyShoe`)을 서버 카탈로그 `Shoe.id`로 옮긴다.
//
// 서버 전송 계약은 카탈로그 id만 취급하므로, 레거시 문자열이 남아 있는 기록은 신발 없이 전송된다.
// 이 타입이 매칭한 id를 `shoes` 컬럼에 덮어쓰면 이후 resolver가 해석에 성공해 `Diary.shoe`로 복원된다.
// SwiftData 스키마를 늘리지 않고 같은 컬럼의 값만 교체하는 방식이다.
//
// 마이그레이션 실행 시점은 아직 정하지 않았다. 여기서는 순수 계산만 제공하고 호출부는 배선하지 않는다.
enum ShoeIdMigrator {
    /// 레거시 신발 문자열을 카탈로그 항목으로 해석한다.
    ///
    /// 1. id 완전 일치 — 카탈로그가 로드되기 전에 복원돼 `legacyShoe`로 떨어진 정상 기록
    /// 2. 표시 이름 일치 — 옛 `ShoeStorage` 슬러그(`"nike-alphafly-3"`)
    ///
    /// 해석하지 못하면 `nil`이다. 카탈로그 id처럼 이름으로 환원되지 않는 값은 2단계에서 걸러지므로
    /// 이미 마이그레이션된 기록에 다시 적용해도 안전하다.
    static func resolve(legacyShoe: String, in catalog: [Shoe]) -> Shoe? {
        guard !legacyShoe.isEmpty else { return nil }

        // 카탈로그 순서에 결과가 좌우되지 않도록 id 오름차순으로 고정한다.
        let sorted = catalog.sorted { $0.id < $1.id }

        if let exact = sorted.first(where: { $0.id == legacyShoe }) { return exact }

        guard let decodedName = LegacyShoeMapper.decodeName(from: legacyShoe) else { return nil }

        let key = normalized(decodedName)

        guard !key.isEmpty else { return nil }

        return sorted.first { shoe in
            nameKeys(of: shoe).contains(key)
        }
    }

    /// 레거시 신발이 남아 있는 일지를 카탈로그 id로 매핑한다.
    /// 반환값은 `일지 id → 카탈로그 Shoe.id`이며, 해석하지 못한 일지는 포함하지 않는다.
    static func migrate(records: [Diary], catalog: [Shoe]) -> [UUID: String] {
        guard !catalog.isEmpty else { return [:] }

        return records.reduce(into: [:]) { result, record in
            guard
                let legacyShoe = record.legacyShoe,
                let resolved = resolve(legacyShoe: legacyShoe, in: catalog)
            else { return }

            result[record.id] = resolved.id
        }
    }

    /// 브랜드 포함 여부와 표기 언어가 제각각이라 가능한 이름 조합을 모두 후보로 둔다.
    private static func nameKeys(of shoe: Shoe) -> Set<String> {
        [
            normalized(shoe.name),
            normalized(shoe.nameKo),
            normalized(shoe.brandName + shoe.name),
            normalized(shoe.brandName + shoe.nameKo),
        ]
    }

    /// 공백·하이픈·마침표와 대소문자 차이를 제거해 비교 키를 만든다.
    private static func normalized(_ value: String) -> String {
        value
            .lowercased()
            .filter { !$0.isWhitespace && $0 != "-" && $0 != "_" && $0 != "." }
    }
}
