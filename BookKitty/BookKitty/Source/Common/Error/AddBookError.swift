//
//  AddBookError.swift
//  BookKitty
//
//  Created by 권승용 on 2/14/25.
//

import BookMatchKit
import Foundation

enum AddBookError: AlertPresentableError {
    case bookNotFound
    case duplicatedBook
    case unknown

    // MARK: - Computed Properties

    var title: String { "책 검색 중 문제가 발생했어요" }

    var body: String {
        switch self {
        case .bookNotFound:
            return "책이 검색되지 않았습니다!"
        case .duplicatedBook:
            return "이미 존재하는 책입니다! 다시 시도해 주세용"
        case .unknown:
            return "알 수 없는 오류가 발생했습니다! 앱을 꼈다 켜 주세요.\n문제가 계속 발생한다면 개발자에게 연락해 주세요!"
        }
    }

    var buttonTitle: String { "확인" }
}
