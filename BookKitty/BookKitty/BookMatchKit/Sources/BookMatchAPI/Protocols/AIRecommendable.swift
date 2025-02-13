import BookMatchCore
import RxSwift

public protocol AIRecommendable {
    func getBookRecommendation(question: String, ownedBooks: [OwnedBook])
        -> Single<AiRecommendationForQuestion>
    func getBookRecommendation(ownedBooks: [OwnedBook]) -> Single<AiRecommendationFromOwnedBooks>
    func getAdditionalBook(question: String, previousBooks: [RawBook]) -> Single<RawBook>
    func getDescription(question: String, books: [RawBook]) -> Single<String>
}
