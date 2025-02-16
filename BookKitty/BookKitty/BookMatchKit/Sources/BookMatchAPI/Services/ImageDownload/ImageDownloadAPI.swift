import BookMatchCore
import NetworkKit
import RxSwift
import UIKit

/// 네이버 책 검색 API와 OpenAI API를 사용하여 도서 검색 및 추천 기능을 제공하는 클라이언트입니다.
public final class ImageDownloadAPI: BaseAPIClient, ImageDownloadable {
    // MARK: - Lifecycle

    override public init(configuration: APIConfiguration) {
        super.init(configuration: configuration)
    }

    // MARK: - Functions

    /// URL로부터 이미지를 다운로드합니다.
    ///
    /// - Parameters:
    ///   - urlString: 이미지 URL 문자열
    /// - Returns: 다운로드된 UIImage
    /// - Throws: BookMatchError.networkError
    public func downloadImage(from urlString: String) -> Single<UIImage> {
        let endpoint = ImageDownloadEndpoint(urlString: urlString)

        return NetworkManager.shared.request(endpoint)
            .map { data -> UIImage in
                guard let data,
                      let image = UIImage(data: data) else {
                    throw BookMatchError.networkError
                }
                return image
            }
            .catch { error in
                .error(BookMatchError.imageDownloadFailed(error.localizedDescription))
            }
    }
}
