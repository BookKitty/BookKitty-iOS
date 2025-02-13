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
