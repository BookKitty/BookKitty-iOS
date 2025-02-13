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
