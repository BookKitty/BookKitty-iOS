import RxSwift
import UIKit

public protocol BookMatchable {
    func matchBook(_ rawData: [[String]], image: UIImage) -> Single<BookItem?>
}
