//
//  NetworkManageable.swift
//  Network
//
//  Created by 권승용 on 1/28/25.
//

import RxSwift

/// 네트워크 요청을 관리하기 위한 프로토콜입니다.
/// 이 프로토콜은 네트워크 요청의 실행과 응답 처리를 추상화합니다.
public protocol NetworkManageable {
    /// 지정된 엔드포인트에 대한 네트워크 요청을 수행합니다.
    /// - Parameter endpoint: 요청할 엔드포인트 정보
    /// - Returns: 응답 데이터를 포함하는 Single 스트림
    /// - Note: Generic 타입 T는 Endpoint 프로토콜을 준수해야 합니다.
    func request<T: Endpoint>(_ endpoint: T) -> Single<T.Response?>
}
