//
//  CreateDiaryRequestFieldMappingTests.swift
//  RunDiaryTests
//
//  계약: docs/api/create-diary-request.md (v1.1 확정본)
//  Models 스킴에는 test action이 없어 ModelsTests가 실행되지 않는다.
//  RouteDownsamplerTests와 같이 실제로 도는 이 타겟에 둔다.
//
//  Diary 최상위 사용자 입력 필드(신발·메모·날씨) 매핑만 다룬다.
//  workout 매핑(id·시간·타임존·스칼라·route·series.metadata)은 CreateDiaryRequestMapperTests에 있다.
//  SUT 생성 헬퍼(makeMapperWorkout 등)는 CreateDiaryRequestMapperTestSupport에서 공유한다.

import Foundation
import Models
import Testing

@Suite("CreateDiaryRequestMapper - 최상위 사용자 입력 필드")
struct CreateDiaryRequestFieldMappingTests {

    // MARK: - 신발

    // SHOE-05(a)
    @Test("카탈로그 신발이 있으면 shoeId가 shoe.id와 같다")
    func request_from_mapsShoeId_whenCatalogShoeExists() {
        // Given
        let shoe = makeMapperCatalogShoe(id: "68f0a1b2c3d4e5f601234567")
        let workout = makeMapperWorkout()
        let diary = makeMapperDiary(workout: workout, shoe: shoe)
        let expectedShoeId = shoe.id

        // When
        let request = CreateDiaryRequestMapper.request(from: diary)

        // Then
        #expect(request.shoeId == expectedShoeId)
    }

    // SHOE-05(b)
    @Test("legacyShoe만 있으면 shoeId는 nil이다")
    func request_from_setsShoeIdNil_whenOnlyLegacyShoeExists() {
        // Given
        let workout = makeMapperWorkout()
        let diary = makeMapperDiary(workout: workout, legacyShoe: "나이키 페가수스")

        // When
        let request = CreateDiaryRequestMapper.request(from: diary)

        // Then
        #expect(request.shoeId == nil)
    }

    // SHOE-05(c)
    @Test("신발이 둘 다 없으면 shoeId는 nil이다")
    func request_from_setsShoeIdNil_whenNoShoeExists() {
        // Given
        let workout = makeMapperWorkout()
        let diary = makeMapperDiary(workout: workout)

        // When
        let request = CreateDiaryRequestMapper.request(from: diary)

        // Then
        #expect(request.shoeId == nil)
    }

    // MARK: - 메모

    // MEMO-01(a)
    @Test("메모가 공백뿐이면 nil로 정규화된다")
    func request_from_normalizesMemoToNil_whenMemoIsWhitespaceOnly() {
        // Given
        let workout = makeMapperWorkout()
        let diary = makeMapperDiary(workout: workout, memo: "   \n\t  ")

        // When
        let request = CreateDiaryRequestMapper.request(from: diary)

        // Then
        #expect(request.memo == nil)
    }

    // MEMO-01(b)
    @Test("메모 앞뒤 공백은 트림되고 본문은 유지된다")
    func request_from_trimsMemoWhitespace_whenMemoHasSurroundingSpaces() {
        // Given
        let workout = makeMapperWorkout()
        let diary = makeMapperDiary(workout: workout, memo: "  컨디션 좋았음  ")
        let expectedMemo = "컨디션 좋았음"

        // When
        let request = CreateDiaryRequestMapper.request(from: diary)

        // Then
        #expect(request.memo == expectedMemo)
    }

    // MEMO-01(c)
    @Test("메모가 2,050자면 2,000자로 절단된다")
    func request_from_truncatesMemo_whenMemoExceedsMaxLength() {
        // Given
        let longMemo = String(repeating: "가", count: 2_050)
        let workout = makeMapperWorkout()
        let diary = makeMapperDiary(workout: workout, memo: longMemo)
        let expectedLength = 2_000

        // When
        let request = CreateDiaryRequestMapper.request(from: diary)

        // Then
        #expect(request.memo?.count == expectedLength)
    }

    // MARK: - 날씨

    // WEATHER-01
    @Test("날씨가 있으면 6개 원시 수치가 변환 없이 그대로 전달된다")
    func request_from_passesThroughAllWeatherRawValues() {
        // Given
        let expectedTemperature = 24.6
        let expectedHumidity = 68
        let expectedWindSpeed = 2.3
        let expectedApparentTemperature = 26.1
        let expectedCloudCover = 0.35
        let expectedPrecipitationAmount = 0.0
        let weather = WeatherData(
            temperature: expectedTemperature,
            humidity: expectedHumidity,
            windSpeed: expectedWindSpeed,
            apparentTemperature: expectedApparentTemperature,
            cloudCover: expectedCloudCover,
            precipitationAmount: expectedPrecipitationAmount
        )
        let workout = makeMapperWorkout()
        let diary = makeMapperDiary(workout: workout, weather: weather)

        // When
        let request = CreateDiaryRequestMapper.request(from: diary)

        // Then
        #expect(request.weather?.temperature == expectedTemperature)
        #expect(request.weather?.humidity == expectedHumidity)
        #expect(request.weather?.windSpeed == expectedWindSpeed)
        #expect(request.weather?.apparentTemperature == expectedApparentTemperature)
        #expect(request.weather?.cloudCover == expectedCloudCover)
        #expect(request.weather?.precipitationAmount == expectedPrecipitationAmount)
    }

    // WEATHER-03
    @Test("apparentTemperature와 cloudCover는 조회값 그대로(nil 포함) 전달된다")
    func request_from_passesThroughApparentTemperatureAndCloudCover() {
        // Given
        let expectedApparentTemperature: Double? = nil
        let expectedCloudCover = 0.42
        let weather = WeatherData(
            temperature: 20.0,
            humidity: 50,
            windSpeed: 1.0,
            apparentTemperature: expectedApparentTemperature,
            cloudCover: expectedCloudCover,
            precipitationAmount: nil
        )
        let workout = makeMapperWorkout()
        let diary = makeMapperDiary(workout: workout, weather: weather)

        // When
        let request = CreateDiaryRequestMapper.request(from: diary)

        // Then
        #expect(request.weather?.apparentTemperature == expectedApparentTemperature)
        #expect(request.weather?.cloudCover == expectedCloudCover)
    }

    // WEATHER-04
    @Test("precipitationAmount는 조회값 그대로 전달된다(0도 유효값으로 유지)")
    func request_from_passesThroughPrecipitationAmount() {
        // Given
        let expectedPrecipitationAmount = 0.0
        let weather = WeatherData(
            temperature: 20.0,
            humidity: 50,
            windSpeed: 1.0,
            apparentTemperature: nil,
            cloudCover: nil,
            precipitationAmount: expectedPrecipitationAmount
        )
        let workout = makeMapperWorkout()
        let diary = makeMapperDiary(workout: workout, weather: weather)

        // When
        let request = CreateDiaryRequestMapper.request(from: diary)

        // Then
        #expect(request.weather?.precipitationAmount == expectedPrecipitationAmount)
    }
}
