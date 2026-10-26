//
//  Shoe+Preview.swift
//  RunDiary
//
//  Created by 김혜지 on 7/31/26.
//

import Models

extension Shoe {
    static var preview: Shoe {
        Shoe(
            id: "nike-alphafly-3",
            brandName: "Nike",
            name: "Nike Alphafly 3",
            nameKo: "나이키 알파플라이 3",
            category: ["en": "Racing", "ko": "레이싱"],
            subcategory: ["en": "Carbon Plate", "ko": "카본 플레이트"],
            tags: ["carbon", "marathon"],
            imageUrl: nil,
            reviewSummary: "장거리 레이스용 최상위 카본화",
            pros: ["뛰어난 반발력", "가벼운 무게"],
            cons: ["높은 가격", "짧은 내구성"],
            description: "마라톤 레이스를 위한 나이키의 플래그십 모델"
        )
    }
}
