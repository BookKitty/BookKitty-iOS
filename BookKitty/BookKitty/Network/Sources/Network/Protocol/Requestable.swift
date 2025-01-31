//
//  Requestable.swift
//  Network
//
//  Created by 권승용 on 1/28/25.
//

import Foundation

/// 네트워크 요청을 생성할 수 있는 타입을 정의하는 프로토콜
public protocol Requestable {
    /// URLRequest 객체로 변환하는 메서드
    /// - Returns: 구성된 URLRequest 객체. 변환에 실패한 경우 nil을 반환
    func toRequest() -> URLRequest?
}
