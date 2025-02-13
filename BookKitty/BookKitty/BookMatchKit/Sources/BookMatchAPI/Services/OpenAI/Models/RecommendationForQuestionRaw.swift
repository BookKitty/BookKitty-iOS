import BookMatchCore

/// GPT 모델의 응답을 `사용자 질문 기반 추천 도서` 데이터로 변환하는 DTO 구조체입니다.
public struct RecommendationForQuestionRaw: Codable {
    // MARK: - Properties

    public let recommendationOwned: [String]
    public let recommendationNew: [String]

    // MARK: - Functions

    /// - Parameters:
    ///    - ownedBooks: 사용자가 보유한 도서 목록
    ///    - Returns: BookMatchCore에서 구현되었으며, APIClient 모듈에서 사용되는 ``RecommendationForQuestion`` 객체
    func toDomain(_ ownedBooks: [OwnedBook]) -> RecommendationForQuestion {
        // 기존 "도서명-저자명" 배열을 순회하며, 초기 전달받은 OwnedBook들 중 일치하는 데이터로 변환합니다.
        let ownedBooks = recommendationOwned.compactMap {
            let arr = $0.split(separator: "-").map { String($0) }
            return ownedBooks.first(where: { $0.title == arr[0] && $0.author == arr[1] })
        }

        let newRawBooks = recommendationNew.map {
            let arr = $0.split(separator: "-").map { String($0) }
            return RawBook(title: arr[0], author: arr[1])
        }

        return RecommendationForQuestion(ownedBooks: ownedBooks, newBooks: newRawBooks)
    }
}
