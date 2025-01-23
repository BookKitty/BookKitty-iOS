//
//  NetworkManager.swift
//  BookKitty
//
//  Created by 권승용 on 1/23/25.
//

import Foundation
import RxSwift

/// 네트워크 기능을 수행하는 객체
final class NetworkManager: NetworkManageable {
    func fetch<T: Decodable>(_: URLRequest) -> Single<T> {
        Single.create { _ in
            // 여기 구현 필요
            // 함수 시그니쳐 변경해도 무방합니다
            Disposables.create()
        }
    }
}
