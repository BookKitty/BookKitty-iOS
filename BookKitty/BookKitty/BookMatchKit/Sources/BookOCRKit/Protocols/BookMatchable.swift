import BookMatchCore
import RxSwift
import UIKit

public protocol BookMatchable {
    func recognizeBookFromImage(_ image: UIImage) -> Single<BookItem>
    func searchBookFromText(_ query: String) -> Single<[BookItem]>
}
