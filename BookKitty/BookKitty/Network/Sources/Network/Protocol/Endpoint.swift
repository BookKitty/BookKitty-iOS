//
//  Endpoint.swift
//  Network
//
//  Created by 권승용 on 1/28/25.
//

import Foundation

/// 네트워크 엔드포인트를 정의하기 위한 프로토콜
/// Requestable과 Responseable 프로토콜을 준수하며 API 엔드포인트의 기본 구성 요소를 정의합니다.
public protocol Endpoint: Requestable, Responseable {
    /// API의 기본 URL (예시: "https://api.example.com")
    var baseURL: String { get }

    /// 엔드포인트의 경로 (예시: "/v1/users")
    var path: String { get }
    
    /// HTTP 요청 메서드
    var method: HTTPMethod { get }
    
    /// HTTP 요청 헤더
    var heaerFields: [String: String] { get }

    /// URL 쿼리 파라미터 배열
    var queryItems: [URLQueryItem] { get }
    
    /// 요청 타임아웃 인터벌
    var timeoutInterval: TimeInterval { get }

    /// 요청에 포함될 데이터
    var data: Data? { get }
}

extension Endpoint {
    /// 프로토콜의 속성들을 사용하여 URLRequest 객체를 생성합니다.
    /// - Returns: 구성된 URLRequest 객체. URL 생성에 실패한 경우 nil을 반환
    public func toRequest() -> URLRequest? {
        var components = URLComponents(string: baseURL)
        components?.path = path
        components?.queryItems = queryItems
        
        guard let url = components?.url else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = heaerFields
        request.timeoutInterval = timeoutInterval
        request.httpBody = data
        
        return request
    }
}
