import BookMatchCore

/// GPT 모델의 응답을 `사용자 보유도서 기반 추천 도서` 데이터로 변환하는 DTO 구조체입니다.
public struct RecommendationFromOwnedRaw: Decodable {
    // MARK: - Properties

    // MARK: Public

    public let recommendations: [String]

    // MARK: - Functions

    // MARK: Internal

    /// - Returns: BookMatchCore에서 구현되었으며, APIClient 모듈에서 사용되는 ``RecommendationFromOwned``
    /// 객체
    func toDomain() -> RecommendationFromOwned {
        let recommendations = recommendations.map {
            let arr = $0.split(separator: "-").map { String($0) }
            return RawBook(title: arr[0], author: arr[1])
        }

        return RecommendationFromOwned(books: recommendations)
    }
}
