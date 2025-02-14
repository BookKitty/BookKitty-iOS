import RxSwift
import UIKit

public protocol ImageDownloadable {
    func downloadImage(from urlString: String) -> Single<UIImage>
}
