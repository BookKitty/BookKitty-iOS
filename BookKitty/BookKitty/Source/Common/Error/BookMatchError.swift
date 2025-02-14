//
//  BookMatchError.swift
//  BookKitty
//
//  Created by 권승용 on 2/14/25.
//

import BookMatchKit
import Foundation

enum BookMatchError: AlertPresentableError {
    case bookNotFound
    case duplicatedBook

    // MARK: - Computed Properties

    var title: String { "책 검색 중 문제가 발생했어요" }

    var body: String {
        switch self {
        case .bookNotFound:
            return "책이 검색되지 않았습니다!"
        case .duplicatedBook:
            return "이미 존재하는 책입니다! 다시 시도해 주세용"
        }
    }

    var buttonTitle: String {
        switch self {
        case .bookNotFound:
            return "확인"
        case .duplicatedBook:
            return "확인"
        }
    }
}
