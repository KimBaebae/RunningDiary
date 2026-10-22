//
//  MetricSeriesPoint.swift
//  Models
//
//  Created by 김혜지 on 7/30/26.
//

// 필드명 `t`/`v`는 series 목표 JSON 스키마({t, v})에 맞춘 의도적 축약이다.
// swiftlint:disable identifier_name
/// 소수 정밀도가 필요한 지표의 다운샘플 시계열 포인트.
/// 정수로 충분한 지표는 `SeriesPoint`를 쓴다. 수직 진폭(cm)·보폭 길이(m)처럼
/// 값의 크기가 작아 정수 반올림 시 정보가 소멸하는 지표만 이 타입을 사용한다.
public struct MetricSeriesPoint: Equatable, Sendable, Codable {
    public let t: Int       // 시작 후 경과 초
    public let v: Double

    public init(t: Int, v: Double) {
        self.t = t
        self.v = v
    }
}
// swiftlint:enable identifier_name
