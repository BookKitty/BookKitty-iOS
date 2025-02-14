import BookMatchCore
import RxSwift

public protocol AIRecommendable {
    func getBookRecommendation(question: String, ownedBooks: [OwnedBook])
        -> Single<RecommendationForQuestion>
    func getBookRecommendation(ownedBooks: [OwnedBook]) -> Single<RecommendationFromOwned>
    func getAdditionalBook(question: String, previousBooks: [RawBook]) -> Single<RawBook>
    func getDescription(question: String, books: [RawBook]) -> Single<String>
}
