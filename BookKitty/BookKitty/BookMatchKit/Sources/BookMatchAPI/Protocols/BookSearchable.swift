import BookMatchCore
import RxSwift

public protocol BookSearchable {
    func searchBooks(query: String, limit: Int) -> Single<[BookItem]>
}
