import BookMatchCore
import RxSwift
import UIKit

public protocol APIClientProtocol {
    func searchBooks(query: String, limit: Int) -> Single<[BookItem]>
    func downloadImage(from urlString: String) -> Single<UIImage>

    func getBookRecommendation(question: String, ownedBooks: [OwnedBook])
        -> Single<AiRecommendationForQuestion>
    func getBookRecommendation(ownedBooks: [OwnedBook]) -> Single<AiRecommendationFromOwnedBooks>
    func getAdditionalBook(question: String, previousBooks: [RawBook]) -> Single<RawBook>
    func getDescription(question: String, books: [RawBook]) -> Single<String>
}
