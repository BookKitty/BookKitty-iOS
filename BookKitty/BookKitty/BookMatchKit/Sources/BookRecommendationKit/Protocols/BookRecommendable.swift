import BookMatchCore
import RxSwift

public protocol BookRecommendable {
    func recommendBooks(from ownedBooks: [OwnedBook]) -> Single<[BookItem]>
    func recommendBooks(for question: String, from ownedBooks: [OwnedBook])
        -> Single<BookMatchModuleOutput>
}
