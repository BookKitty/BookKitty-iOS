import RxSwift
import UIKit

public protocol TextExtractable {
    func extractText(from image: UIImage) -> Single<[String]>
}
