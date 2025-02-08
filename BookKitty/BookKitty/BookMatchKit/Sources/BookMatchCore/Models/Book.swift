/// 네이버 책 검색 API로부터 받은 상세 도서 정보를 나타내는 구조체입니다.
public struct BookItem: Codable, Identifiable, Hashable {
    // MARK: - Properties

    // MARK: - Public

    public let id: String
    public let title: String
    public let link: String
    public let image: String
    public let author: String
    public let discount: String?
    public let publisher: String
    public let isbn: String
    public let description: String
    public let pubdate: String?

    // MARK: - Lifecycle

    public init(
        id: String,
        title: String,
        link: String,
        image: String,
        author: String,
        discount: String? = nil,
        publisher: String,
        isbn: String,
        description: String,
        pubdate: String? = nil
    ) {
        self.id = id
        self.title = title
        self.link = link
        self.image = image
        self.author = author
        self.discount = discount
        self.publisher = publisher
        self.isbn = isbn
        self.description = description
        self.pubdate = pubdate
    }
}

/// 기본적인 도서 정보(제목, 저자)를 나타내는 구조체입니다.
/// GPT 모델과의 통신에 사용됩니다.
public struct RawBook: Codable, Hashable {
    // MARK: - Properties

    // MARK: - Public

    public let title: String
    public let author: String

    // MARK: - Lifecycle

    public init(title: String, author: String) {
        self.title = title
        self.author = author
    }
}

/// 사용자가 보유한 도서 정보를 나타내는 구조체입니다.
public struct OwnedBook: Codable, Identifiable, Hashable {
    // MARK: - Properties

    // MARK: - Public

    public let id: String // ISBN
    public let title: String
    public let author: String

    // MARK: - Lifecycle

    public init(id: String, title: String, author: String) {
        self.id = id
        self.title = title
        self.author = author
    }
}
