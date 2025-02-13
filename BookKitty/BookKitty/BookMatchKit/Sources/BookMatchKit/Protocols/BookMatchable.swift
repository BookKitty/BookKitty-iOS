import BookMatchCore
import RxSwift
import UIKit

public protocol BookMatchable {
    func matchBook(image: UIImage) -> Single<BookItem?>
}
