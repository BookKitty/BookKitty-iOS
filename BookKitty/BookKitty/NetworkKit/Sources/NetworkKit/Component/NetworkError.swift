//
//  NetworkError.swift
//  Network
//
//  Created by 권승용 on 1/28/25.
//

/// 네트워크 요청 중 발생할 수 있는 다양한 네트워크 관련 오류를 나타내는 열거형.
public enum NetworkError: Error, Equatable {
    /// JSON 디코딩에 실패했을 때를 나타냅니다.
    case decodingFailed

    /// URLResponse에서 HTTPURLResponse로 타입 변환에 실패했을 때를 나타냅니다.
    case responseTypeCastingFailed

    /// 잘못된 URL을 나타냅니다.
    case invalidURL

    /// 1xx HTTP 정보성 오류를 나타냅니다.
    case informationalError(Int)

    /// 3xx HTTP 리다이렉션 오류를 나타냅니다.
    case redirectionError(Int)

    /// 4xx HTTP 클라이언트 오류를 나타냅니다.
    case clientError(Int)

    /// 5xx HTTP 서버 오류를 나타냅니다.
    case serverError(Int)

    /// 명시되지 않은 알 수 없는 오류를 나타냅니다.
    case unknownError(Int)
}
