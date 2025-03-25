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

public final class ImageDownloader: Sendable {
    // MARK: - Static Properties

    public static let `default` = ImageDownloader(name: "default")

    // MARK: - Properties

    private let downloadTimeout: TimeInterval = 15.0
    private let name: String
    private let session: URLSession

    private let sessionDelegate: SessionDelegate

    // MARK: - Lifecycle

    public init(
        name: String
    ) {
        self.name = name
        sessionDelegate = SessionDelegate()

        session = URLSession(
            configuration: URLSessionConfiguration.ephemeral,
            delegate: sessionDelegate,
            delegateQueue: nil
        )
    }

    deinit { session.invalidateAndCancel() }

    // MARK: - Functions

    public func createTask(with url: URL) async throws -> DownloadTask {
        let request = URLRequest(
            url: url,
            cachePolicy: .reloadIgnoringLocalCacheData,
            timeoutInterval: downloadTimeout
        )

        guard let url = request.url, !url.absoluteString.isEmpty else {
            throw NeoImageError.requestError(reason: .invalidURL)
        }

        return await createDownloadTask(url: url, request: request)
    }

    @discardableResult
    public func downloadImage(
        with downloadTask: DownloadTask,
        for url: URL,
        hashedKey: String
    ) async throws -> ImageLoadingResult {
        let imageData = try await downloadImageData(with: downloadTask)

        guard let image = UIImage(data: imageData) else {
            throw NeoImageError.responseError(reason: .invalidImageData)
        }

        try? await ImageCache.shared.store(
            imageData,
            for: hashedKey
        )

        NeoLogger.shared.debug("Image stored in cache with key: \(url.absoluteString)")

        return ImageLoadingResult(
            image: image,
            url: url,
            originalData: imageData
        )
    }
}

extension ImageDownloader {
    /// 이미지 데이터를 다운로드합니다.
    /// - Parameter url: 다운로드할 URL
    /// - Returns: 다운로드 작업과 데이터 튜플
    private func downloadImageData(with downloadTask: DownloadTask) async throws -> Data {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<
            Data,
            Error
        >) in
            Task {
                guard let sessionTask = await downloadTask.sessionTask else {
                    continuation
                        .resume(throwing: NeoImageError.requestError(reason: .invalidSessionTask))
                    return
                }

                if await sessionTask.isCompleted,
                   let taskResult = await sessionTask.taskResult {
                    switch taskResult {
                    case let .success((data, _)):
                        if data.isEmpty {
                            continuation
                                .resume(
                                    throwing: NeoImageError
                                        .responseError(reason: .invalidImageData)
                                )
                        } else {
                            continuation.resume(returning: data)
                        }
                    case let .failure(error):
                        continuation.resume(throwing: error)
                    }
                }

                await sessionTask.onCallbackTaskDone.delegate(on: self) { _, value in
                    let (result, _) = value

                    switch result {
                    case let .success((data, _)):
                        if data.isEmpty {
                            continuation
                                .resume(
                                    throwing: NeoImageError
                                        .responseError(reason: .invalidImageData)
                                )
                        } else {
                            continuation.resume(returning: data)
                        }
                    case let .failure(error):
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }

    /// 다운로드 작업을 생성하거나 기존 작업을 재사용합니다.
    /// - Parameters:
    ///   - url: 다운로드할 URL
    ///   - request: URL 요청
    /// - Returns: 다운로드 작업
    private func createDownloadTask(url: URL, request: URLRequest) async -> DownloadTask {
        // 기존 작업이 있는지 확인
        if let existingTask = await sessionDelegate.task(for: url) {
            return await sessionDelegate.append(existingTask)
        } else {
            // 새 작업 생성
            let sessionDataTask = session.dataTask(with: request)
            return await sessionDelegate.add(sessionDataTask, url: url)
        }
    }
}
