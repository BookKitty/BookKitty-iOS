/// 도서 매칭 모듈의 입력 데이터를 나타내는 구조체입니다.
public struct BookMatchModuleInput {
    // MARK: Lifecycle

    public init(
        question: String,
        ownedBooks: [OwnedBook]
    ) {
        self.question = question
        self.ownedBooks = ownedBooks
    }

    // MARK: Public

    public let question: String
    public let ownedBooks: [OwnedBook]
}

/// 도서 매칭 모듈의 출력 데이터를 나타내는 구조체입니다.
public struct BookMatchModuleOutput {
    // MARK: Lifecycle

    public init(
        ownedISBNs: [String],
        newBooks: [BookItem],
        description: String
    ) {
        self.ownedISBNs = ownedISBNs
        self.newBooks = newBooks
        self.description = description
    }

    // MARK: Public

    public let ownedISBNs: [String] // isbn 코드 배열
    public let newBooks: [BookItem]
    public let description: String
}
