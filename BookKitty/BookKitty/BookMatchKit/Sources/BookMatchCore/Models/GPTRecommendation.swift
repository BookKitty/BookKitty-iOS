/// `사용자 질문 기반 도서 추천` 결과를 담는 구조체입니다.
public struct GPTRecommendationForQuestion: Codable {
    // MARK: - Properties

    // MARK: - Public

    public let ownedBooks: [OwnedBook]
    public let newBooks: [RawBook]

    // MARK: - Lifecycle

    public init(ownedBooks: [OwnedBook], newBooks: [RawBook]) {
        self.ownedBooks = ownedBooks
        self.newBooks = newBooks
    }
}

/// `보유 도서 기반 도서 추천` 결과를 담는 구조체입니다.
public struct GPTRecommendationFromOwnedBooks: Codable {
    // MARK: - Properties

    // MARK: - Public

    public let books: [RawBook]

    // MARK: - Lifecycle

    public init(books: [RawBook]) {
        self.books = books
    }
}
