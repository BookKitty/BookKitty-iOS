import Foundation

/// 다운로드 세션을 위한 델리게이트 클래스
/// URLSession의 이벤트를 처리하고 다운로드 작업을 관리합니다.
/// URLSessionDataDelegate는 @objc 프로토콜이며, NSObjectProtocol을 채택하는 URLSessionDelegate를 상속합니다. 따라서, 해당 Protocol을 채택하는 가장 간단한 방법은 NSObject를 상속하는 것입니다.
/// 하지만, Actor는 상속이 불가능하기 때문에, actor를 통해 직렬화를 보장받는 대신 NSLock을 사용해 동시성 업데이트 문제를 방지하고 있습니다.
/// 기존 Objective-C/NSObject 기반 시스템과의 호환성도 유지할 수 있는 적절한 선택
private class SessionDelegate: NSObject, URLSessionDataDelegate, @unchecked Sendable {
    
    // MARK: - 프로퍼티
    
    /// 인증 챌린지 처리를 위한 핸들러
    var onReceiveChallenge: ((URLAuthenticationChallenge) async -> (URLSession.AuthChallengeDisposition, URLCredential?))?
    
    /// HTTP 상태 코드 검증을 위한 핸들러
    var onValidateStatusCode: ((Int) -> Bool)?
    
    /// 실행 중인 다운로드 작업을 추적하기 위한 딕셔너리
    private var tasks = [URL: URLSessionTask]()
    private let lock = NSLock()
    
    // MARK: - 작업 관리 메서드
    
    /// 특정 URL에 대한 다운로드 작업 취소
    func cancelTasks(for url: URL) {
        lock.lock()
        defer { lock.unlock() }
        
        tasks[url]?.cancel()
        tasks[url] = nil
    }
    
    /// 모든 다운로드 작업 취소
    func cancelAllTasks() {
        lock.lock()
        defer { lock.unlock() }
        
        tasks.values.forEach { $0.cancel() }
        tasks.removeAll()
    }
    
    // MARK: - URLSessionDataDelegate 메서드
    
    /// 서버 인증 챌린지 처리
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didReceive challenge: URLAuthenticationChallenge
    ) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        await onReceiveChallenge?(challenge) ?? (.performDefaultHandling, nil)
    }
    
    /// 서버 응답 검증 및 처리
    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse
    ) async -> URLSession.ResponseDisposition {
        // HTTP 응답 및 상태 코드 검증
        guard let httpResponse = response as? HTTPURLResponse,
              onValidateStatusCode?(httpResponse.statusCode) == true else {
            return .cancel
        }
        return .allow
    }
    
    /// 데이터 수신 처리 (필요한 경우 구현)
    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive data: Data
    ) {
        // kf.setImage의 기본 구현에서는 특별한 처리가 필요 없음
    }
}
