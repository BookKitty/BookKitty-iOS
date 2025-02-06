import BookMatchCore
import RxSwift

public protocol APIClientProtocol {
    func searchBooks(query: String, limit: Int) -> Single<[BookItem]>
    func getBookRecommendation(question: String, ownedBooks: [OwnedBook])
        -> Single<GPTRecommendationForQuestion>
    func getBookRecommendation(ownedBooks: [OwnedBook]) -> Single<GPTRecommendationFromOwnedBooks>
    func getAdditionalBook(question: String, previousBooks: [RawBook]) -> Single<RawBook>
    func getDescription(question: String, books: [RawBook]) -> Single<String>
}
