//
//  DataError.swift
//  BookKitty
//
//  Created by 권승용 on 2/13/25.
//

enum DataError: AlertPresentableError {
    case decodingFailed

    // MARK: - Computed Properties

    var title: String { "데이터 에러" }

    var body: String {
        switch self {
        case .decodingFailed:
            return "디코딩 실패"
        }
    }

    var buttonTitle: String { "확인" }
}
