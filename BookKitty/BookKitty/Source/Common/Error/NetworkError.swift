//
// NetworkError.swift
//  BookKitty
//
//  Created by 권승용 on 2/13/25.
//

enum NetworkError: AlertPresentableError {
    case networkUnstable

    // MARK: - Computed Properties

    var title: String { "네트워크 오류" }

    var body: String {
        switch self {
        case .networkUnstable:
            return "네트워크가 안정적이지 않습니다. 네트워크 환경을 확인해 주세요!"
        }
    }

    var buttonTitle: String {
        "확인"
    }
}
