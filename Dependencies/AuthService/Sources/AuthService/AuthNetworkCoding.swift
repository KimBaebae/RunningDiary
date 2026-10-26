//
//  AuthNetworkCoding.swift
//  AuthService
//
//  Created by 김혜지 on 8/25/26.
//

@preconcurrency import SimpleNetwork

/// AuthService의 `URLSessionService` 기본 encoder/decoder 팩토리.
///
/// SimpleNetwork 1.x는 snake_case 변환이 라이브러리 내부 고정값이었다. 2.0.0부터는
/// `URLSessionService.init`이 encoder/decoder를 필수로 요구하므로, 호출부가 값을 직접
/// 골라야 한다. 여기 지정한 `.convertToSnakeCase` / `.convertFromSnakeCase`는
/// SimpleNetwork의 고정값이 아니라 **1.x와 동일한 전송 바이트를 유지하기 위해 이 앱이
/// 선택한 값**이다. `AppleLoginService`/`TokenRefresher`/`AuthenticatedNetworkService`
/// 세 호출부가 동일 조합을 반복하므로 이 팩토리로 모은다.
public enum AuthNetworkCoding {
    public static func encoder() -> any BodyEncoder {
        JSONBodyEncoder(keyEncodingStrategy: .convertToSnakeCase)
    }

    public static func decoder() -> any ResponseDecoder {
        JSONResponseDecoder(keyDecodingStrategy: .convertFromSnakeCase)
    }
}
