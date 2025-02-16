import BookMatchCore
import RxSwift

public protocol _BookSearchable {
    func searchBooks(query: String, limit: Int) -> Single<[BookItem]>
}
