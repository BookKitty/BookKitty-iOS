import Foundation
import UIKit

/// 이미지 다운로드 결과 구조체 (스레드 안전)
public struct ImageLoadingResult: Sendable {
    public let image: UIImage
    public let url: URL?
    public let originalData: Data
}

/// 이미지 다운로드 관리 액터 (동시성 제어)
public actor ImageDownloadManager {
    
    // MARK: - 싱글톤 & 초기화
    public static let shared = ImageDownloadManager()
    private var session: URLSession
    private let sessionDelegate = SessionDelegate()
    
    private init() {
        let config = URLSessionConfiguration.ephemeral
        session = URLSession(configuration: config, delegate: sessionDelegate, delegateQueue: nil)
        setupDelegates()
    }
    
    // MARK: - 핵심 다운로드 메서드 (kf.setImage에서 사용)
    /// 이미지 비동기 다운로드 (async/await)
    public func downloadImage(with url: URL) async throws -> ImageLoadingResult {
        let request = URLRequest(url: url)
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<400).contains(httpResponse.statusCode) else {
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
private extension ImageDownloadManager {
    /// actor의 상태를 직접 변경하지 않고 클로저를 설정하는 것이기에 nonisolated를 기입하여, 해당 메서드가 actor의 격리된 상태에 접근하지 않음을 알려줌
    nonisolated func setupDelegates() {
        sessionDelegate.onReceiveChallenge = { [weak self] challenge in
            guard let self else {return (.performDefaultHandling, nil)}
            return await handleAuthChallenge(challenge)
        }
        
        sessionDelegate.onValidateStatusCode = { code in
            (200..<400).contains(code)
        }
    }
    
    /// 인증 처리 핸들러
    func handleAuthChallenge(_ challenge: URLAuthenticationChallenge) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        guard let trust = challenge.protectionSpace.serverTrust else {
            return (.cancelAuthenticationChallenge, nil)
        }
        return (.useCredential, URLCredential(trust: trust))
    }
}

// MARK: - 세션 델리게이트 구현 (간소화 버전)
private class SessionDelegate: NSObject, URLSessionDataDelegate, @unchecked Sendable {
    var onReceiveChallenge: ((URLAuthenticationChallenge) async -> (URLSession.AuthChallengeDisposition, URLCredential?))?
    var onValidateStatusCode: ((Int) -> Bool)?
    
    private var tasks = [URL: URLSessionTask]()
    
    func cancelTasks(for url: URL) {
        tasks[url]?.cancel()
        tasks[url] = nil
    }
    
    func cancelAllTasks() {
        tasks.values.forEach { $0.cancel() }
        tasks.removeAll()
    }
    
    // 필수 델리게이트 메서드만 구현
    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        await onReceiveChallenge?(challenge) ?? (.performDefaultHandling, nil)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse) async -> URLSession.ResponseDisposition {
        guard let httpResponse = response as? HTTPURLResponse,
              onValidateStatusCode?(httpResponse.statusCode) == true else {
            return .cancel
        }
        return .allow
    }
}
