//
//  Shoe.swift
//  Models
//
//  Created by 김혜지 on 4/22/26.
//

import Foundation

/// 서버 신발 카탈로그의 한 항목.
///
/// 이 타입은 카탈로그에서 조회한 신발만 표현한다.
/// 카탈로그로 해석되지 않은 로컬 저장 문자열은 `Shoe`로 위장하지 않고 `Diary.legacyShoe`가 보관한다.
public struct Shoe: Identifiable, Equatable, Hashable, Sendable, Decodable {
    public let id: String
    public let brandName: String
    public let name: String     // 영어 이름
    public let nameKo: String   // 한국어 이름

    /// 언어 설정이 한국어면 `nameKo`, 그 외에는 `name` 반환
    public var displayName: String {
        Locale.current.language.languageCode?.identifier == "ko" ? nameKo : name
    }
    public let category: [String: String]
    public let subcategory: [String: String]
    public let tags: [String]
    public let imageUrl: String?
    public let reviewSummary: String?
    public let pros: [String]
    public let cons: [String]
    public let description: String?

    public init(
        id: String,
        brandName: String,
        name: String,
        nameKo: String,
        category: [String: String],
        subcategory: [String: String],
        tags: [String],
        imageUrl: String?,
        reviewSummary: String?,
        pros: [String],
        cons: [String],
        description: String?
    ) {
        self.id = id
        self.brandName = brandName
        self.name = name
        self.nameKo = nameKo
        self.category = category
        self.subcategory = subcategory
        self.tags = tags
        self.imageUrl = imageUrl
        self.reviewSummary = reviewSummary
        self.pros = pros
        self.cons = cons
        self.description = description
    }
}
