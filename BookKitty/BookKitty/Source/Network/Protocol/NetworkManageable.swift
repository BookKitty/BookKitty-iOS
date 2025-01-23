//
//  NetworkManageable.swift
//  BookKitty
//
//  Created by 권승용 on 1/23/25.
//

import Foundation
import RxSwift

/// NetworkManageable 프로토콜은 네트워크 통신 기능을 추상화하는 프로토콜입니다.
/// 이 프로토콜을 준수하는 타입은 기본적인 네트워크 통신 기능을 구현해야 합니다.
protocol NetworkManageable {
    // 내부 요구사항은 추후 변경됩니다

    /// 주어진 URLRequest를 사용하여 네트워크 요청을 수행하고 결과를 디코딩합니다.
    /// - Parameter request: 실행할 네트워크 요청 정보를 담고 있는 URLRequest 객체
    /// - Returns: 디코딩된 결과를 포함하는 Single 객체. 성공 시 제네릭 타입 T의 인스턴스를 반환하고, 실패 시 에러를 방출합니다.
    /// - Note: T는 반드시 Decodable 프로토콜을 준수해야 합니다.
    func fetch<T: Decodable>(_ request: URLRequest) -> Single<T>
}
