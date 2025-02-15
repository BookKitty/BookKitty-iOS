import BookMatchCore
import RxSwift
import UIKit

public protocol BookMatchable {
    func matchBook(_ image: UIImage) -> Single<BookItem>
}
