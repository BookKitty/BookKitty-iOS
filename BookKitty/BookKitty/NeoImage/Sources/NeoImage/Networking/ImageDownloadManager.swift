import Foundation
import UIKit

/// 이미지 다운로드 결과 구조체
public struct ImageLoadingResult: Sendable {
    public let image: UIImage
    public let url: URL?
    public let originalData: Data
}

/// 이미지 다운로드 관리 액터 (동시성 제어)
public actor ImageDownloadManager {
    // MARK: - Static Properties

    // MARK: - 싱글톤 & 초기화

    public static let shared = ImageDownloadManager()

    // MARK: - Properties

    private var session: URLSession
    private let sessionDelegate = SessionDelegate()

    // MARK: - Lifecycle

    private init() {
        let config = URLSessionConfiguration.ephemeral
        session = URLSession(configuration: config, delegate: sessionDelegate, delegateQueue: nil)
        setupDelegates()
    }

    // MARK: - Functions

    // MARK: - 핵심 다운로드 메서드 (kf.setImage에서 사용)

    /// 이미지 비동기 다운로드 (async/await)
    public func downloadImage(with url: URL) async throws -> ImageLoadingResult {
        let request = URLRequest(url: url)
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200 ..< 400).contains(httpResponse.statusCode) else {
//            throw CacheError.invalidHTTPStatusCode
            throw CacheError.invalidData
        }

        guard let image = UIImage(data: data) else {
//            throw KingfisherError.imageMappingError
            throw CacheError.dataToImageConversionFailed
        }

        return ImageLoadingResult(image: image, url: url, originalData: data)
    }

    /// URL 기반 다운로드 취소
    public func cancelDownload(for url: URL) {
        sessionDelegate.cancelTasks(for: url)
    }

    /// 전체 다운로드 취소
    public func cancelAllDownloads() {
        sessionDelegate.cancelAllTasks()
    }
}

// MARK: - 내부 세션 관리 확장

extension ImageDownloadManager {
    /// actor의 상태를 직접 변경하지 않고 클로저를 설정하는 것이기에 nonisolated를 기입하여, 해당 메서드가 actor의 격리된 상태에 접근하지 않음을 알려줌
    private nonisolated func setupDelegates() {
        sessionDelegate.onReceiveChallenge = { [weak self] challenge in
            guard let self else {
                return (.performDefaultHandling, nil)
            }
            return await handleAuthChallenge(challenge)
        }

        sessionDelegate.onValidateStatusCode = { code in
            (200 ..< 400).contains(code)
        }
    }

    /// 인증 처리 핸들러
    private func handleAuthChallenge(_ challenge: URLAuthenticationChallenge) async
        -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        guard let trust = challenge.protectionSpace.serverTrust else {
            return (.cancelAuthenticationChallenge, nil)
        }
        return (.useCredential, URLCredential(trust: trust))
    }
}
