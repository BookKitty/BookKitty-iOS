import Foundation
import UIKit

public struct ImageLoadingResult: Sendable {
    // MARK: - Properties

    public let image: UIImage
    public let url: URL?
    public let originalData: Data

    // MARK: - Lifecycle

    public init(image: UIImage, url: URL? = nil, originalData: Data) {
        self.image = image
        self.url = url
        self.originalData = originalData
    }
}

typealias DownloadResult = Result<ImageLoadingResult, NeoImageError>

public final class ImageDownloader: Sendable {
    // MARK: - Static Properties

    public static let `default` = ImageDownloader(name: "default")

    // MARK: - Properties

    private let downloadTimeout: TimeInterval = 15.0
    private let name: String
    private let session: URLSession

    private let requestsUsePipelining: Bool
    private let sessionDelegate: SessionDelegate

    // MARK: - Lifecycle

    public init(
        name: String,
        requestsUsePipelining: Bool = false
    ) {
        self.name = name
        self.requestsUsePipelining = requestsUsePipelining
        sessionDelegate = SessionDelegate()

        session = URLSession(
            configuration: URLSessionConfiguration.ephemeral,
            delegate: sessionDelegate,
            delegateQueue: nil
        )
    }

    deinit { session.invalidateAndCancel() }

    // MARK: - Functions

    @discardableResult
    public func downloadImageData(with url: URL) async throws -> Data {
        let downloadTask = DownloadTask()

        let context = try await createDownloadContext(with: url)
        let (actualDownloadTask, imageData) = try await createDownloadTask(context: context)

        await downloadTask.linkToTask(actualDownloadTask)

        return imageData
    }

    /// Downloads an image with a URL and option.
    /// - Parameters:
    ///   - url: Target URL.
    ///   - options: The options that can control download behavior.
    /// - Returns: The image loading result.
    public func downloadImage(with url: URL) async throws -> ImageLoadingResult {
        // 이미지 데이터 다운로드
        let imageData = try await downloadImageData(with: url)

        guard let image = UIImage(data: imageData) else {
            throw NeoImageError.responseError(reason: .invalidImageData)
        }

        return ImageLoadingResult(image: image, url: url, originalData: imageData)
    }

    private func createDownloadContext(with url: URL) async throws -> DownloadingContext {
        var request = URLRequest(
            url: url,
            cachePolicy: .reloadIgnoringLocalCacheData,
            timeoutInterval: downloadTimeout
        )
        request.httpShouldUsePipelining = requestsUsePipelining

        guard let url = request.url, !url.absoluteString.isEmpty else {
            throw NeoImageError.requestError(reason: .invalidURL(request: request))
        }

        return DownloadingContext(url: url, request: request)
    }

    private func createDownloadTask(context: DownloadingContext) async throws
        -> (DownloadTask, Data) {
        // 여러 요청이 동시에 실행될 경우를 위한 액터 또는 동기화 메커니즘 필요
        try await withCheckedThrowingContinuation { continuation in
            // 기존 태스크 확인 (중복 다운로드 방지)
            if let existingTask = sessionDelegate.task(for: context.url) {
                existingTask.onTaskDone.delegate(on: self) { _, values in
                    let (result, callbacks) = values
                    let downloadResult: DownloadResult

                    switch result {
                    case let .success((data, _)):
                        if let image = UIImage(data: data) {
                            let imageResult = ImageLoadingResult(
                                image: image,
                                url: context.url,
                                originalData: data
                            )

                            downloadResult = .success(imageResult)
                        } else {
                            downloadResult = .failure(
                                NeoImageError
                                    .responseError(reason: .invalidImageData)
                            )
                        }
                    case let .failure(error):
                        downloadResult = .failure(error)
                    }

                    // 모든 콜백 호출
                    for callbackItem in callbacks {
                        callbackItem.onCompleted?.call(downloadResult)
                    }
                }

                let downloadTask = DownloadTask()

                let onCompleted = Delegate<DownloadResult, Void>()

                onCompleted.delegate(on: self) { _, result in
                    switch result {
                    case let .success(imageResult):
                        continuation.resume(returning: (downloadTask, imageResult.originalData))
                    case let .failure(error):
                        continuation.resume(throwing: error)
                    }
                }

                let callback = SessionDataTask.TaskCallback(onCompleted: onCompleted)
                let task = sessionDelegate.append(existingTask, callback: callback)

                Task {
                    await downloadTask.linkToTask(task)
                }
            } else {
                let sessionDataTask = session.dataTask(with: context.request)
                let onCompleted = Delegate<DownloadResult, Void>()
                let callback = SessionDataTask.TaskCallback(onCompleted: onCompleted)

                let downloadTask = sessionDelegate.add(
                    sessionDataTask,
                    url: context.url,
                    callback: callback
                )
                Task {
                    await downloadTask.sessionTask?.onTaskDone.delegate(on: self) { _, values in
                        let (result, callbacks) = values

                        // 결과를 DownloadResult로 변환
                        let downloadResult: DownloadResult
                        switch result {
                        case let .success((data, _)):
                            if let image = UIImage(data: data) {
                                let imageResult = ImageLoadingResult(
                                    image: image,
                                    url: context.url,
                                    originalData: data
                                )
                                downloadResult = .success(imageResult)
                            } else {
                                downloadResult = .failure(
                                    NeoImageError
                                        .responseError(reason: .invalidImageData)
                                )
                            }
                        case let .failure(error):
                            downloadResult = .failure(error)
                        }

                        // 모든 콜백 호출
                        for callbackItem in callbacks {
                            callbackItem.onCompleted?.call(downloadResult)
                        }
                    }
                }

                onCompleted.delegate(on: self) { _, result in
                    switch result {
                    case let .success(imageResult):
                        continuation.resume(returning: (downloadTask, imageResult.originalData))
                    case let .failure(error):
                        continuation.resume(throwing: error)
                    }
                }

                sessionDataTask.resume()
            }
        }
    }
}

extension ImageDownloader {
    struct DownloadingContext {
        let url: URL
        let request: URLRequest
    }
}
