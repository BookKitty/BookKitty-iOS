/// 네이버 책 검색 API로부터 받은 상세 도서 정보를 나타내는 구조체입니다.
public struct BookItem: Decodable, Identifiable, Hashable {
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
