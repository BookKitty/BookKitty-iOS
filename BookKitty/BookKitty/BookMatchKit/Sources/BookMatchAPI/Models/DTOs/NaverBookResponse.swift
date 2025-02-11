import BookMatchCore

struct NaverBooksResponse: Codable {
    let lastBuildDate: String
    let total: Int
    let start: Int
    let display: Int
    let items: [NaverBookDTO]
}

struct NaverBookDTO: Codable {
    // MARK: - Properties

    let title: String
    let link: String
    let image: String
    let author: String
    let discount: String?
    let publisher: String
    let isbn: String
    let description: String
    let pubdate: String?

    // MARK: - Functions

    func toBookItem() -> BookItem {
        BookItem(
            id: isbn,
            title: title,
            link: link,
            image: image,
            author: author,
            discount: discount,
            publisher: publisher,
            isbn: isbn,
            description: description,
            pubdate: pubdate
        )
    }
}
