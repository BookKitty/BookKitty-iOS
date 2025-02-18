import BookMatchCore
import RxSwift

public protocol BookSearchable {
    func searchByTitleAndAuthor(from sourceBook: RawBook) -> Single<[BookItem]>
    func searchProgressively(from textData: [String]) -> Single<[BookItem]>
    func searchByQuery(from query: String) -> Single<[BookItem]>
}
