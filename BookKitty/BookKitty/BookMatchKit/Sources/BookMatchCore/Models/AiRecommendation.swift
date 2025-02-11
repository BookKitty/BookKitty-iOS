/// `사용자 질문 기반 도서 추천` 결과를 담는 구조체입니다.
public struct AiRecommendationForQuestion: Codable {
    public init(ownedBooks: [OwnedBook], newBooks: [RawBook]) {
        self.ownedBooks = ownedBooks
        self.newBooks = newBooks
    }

    public let ownedBooks: [OwnedBook]
    public let newBooks: [RawBook]
}

/// `보유 도서 기반 도서 추천` 결과를 담는 구조체입니다.
public struct AiRecommendationFromOwnedBooks: Codable {
    public init(books: [RawBook]) {
        self.books = books
    }

    public let books: [RawBook]
}
