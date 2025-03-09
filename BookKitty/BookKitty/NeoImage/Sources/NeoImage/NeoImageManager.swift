import Foundation
import UIKit

public final class NeoImageManager: Sendable {
    // MARK: - Static Properties

    /// NeoImage 전체에서 사용되는 공유 매니저 인스턴스
    public static let shared = NeoImageManager()

    // MARK: - Properties

    public let cache: ImageCache
    public let downloader: ImageDownloader

    // MARK: - Lifecycle

    // MARK: - Initialization

    /// 지정된 다운로더와 캐시로 이미지 다운로드 매니저를 생성합니다.
    public init(
        downloader: ImageDownloader = .default,
        cache: ImageCache = ImageCache(name: "default")
    ) {
        self.downloader = downloader
        self.cache = cache
    }

    // MARK: - Functions

    // MARK: - Image Downloading

    /// URL에서 이미지를 다운로드하고 처리합니다.
    /// - Parameters:
    ///   - url: 이미지를 다운로드할 URL
    ///   - options: 이미지 처리 옵션
    /// - Returns: 처리된 이미지와 관련 정보를 포함하는 `ImageLoadingResult`
    public func downloadImage(
        with url: URL,
        options: NeoImageOptions? = nil
    ) async throws -> ImageLoadingResult {
        let cacheKey = url.absoluteString

        if let cachedData = try? await cache.retrieveImage(forKey: cacheKey),
           let cachedImage = UIImage(data: cachedData) {
            return ImageLoadingResult(
                image: cachedImage,
                url: url,
                originalData: cachedData
            )
        }

        // 캐시에 없으면 다운로드
        let imageData = try await downloader.downloadImageData(with: url)

        guard let image = UIImage(data: imageData) else {
            throw NeoImageError.responseError(reason: .invalidImageData)
        }

        // 다운로드 결과 캐싱
        try? await cache.store(imageData, forKey: cacheKey)

        let result = ImageLoadingResult(
            image: image,
            url: url,
            originalData: imageData
        )

        // 이미지 프로세서가 있으면 이미지 처리
        if let processor = options?.processor {
            let processedImage = try await processor.process(result.image)

            return ImageLoadingResult(
                image: processedImage,
                url: url,
                originalData: result.originalData
            )
        }

        return result
    }
}
