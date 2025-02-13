/// `보유 도서 기반 도서 추천` 결과를 담는 구조체입니다.
public struct RecommendationFromOwned: Decodable {
    // MARK: - Properties

    public let books: [RawBook]

    // MARK: - Lifecycle

    public init(books: [RawBook]) {
        self.books = books
    }
}
