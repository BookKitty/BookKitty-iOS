import BookMatchCore

public protocol APIClientProtocol {
    func searchBooks(query: String, limit: Int) async throws -> [BookItem]
    func getBookRecommendation(question: String, ownedBooks: [OwnedBook]) async throws
        -> GPTRecommendationForQuestion
    func getBookRecommendation(ownedBooks: [OwnedBook]) async throws
        -> GPTRecommendationFromOwnedBooks
    func getAdditionalBook(question: String, previousBooks: [RawBook]) async throws -> RawBook
    func getDescription(question: String, books: [RawBook]) async throws -> String
}
