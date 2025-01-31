//
//  Responseable.swift
//  Network
//
//  Created by 권승용 on 1/28/25.
//

/// 디코딩 가능한 응답 타입을 정의하는 프로토콜
public protocol Responseable {
    /// 네트워크 응답을 디코딩할 타입을 지정하는 연관 타입
    associatedtype Response: Decodable
}
