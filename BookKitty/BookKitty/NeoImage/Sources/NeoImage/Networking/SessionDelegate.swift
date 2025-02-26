import Foundation

public class SessionDelegate: NSObject, URLSessionDataDelegate, @unchecked Sendable {
    // MARK: - Properties

    var onReceiveChallenge: ((URLAuthenticationChallenge) async -> (
        URLSession.AuthChallengeDisposition,
        URLCredential?
    ))?
    var onValidateStatusCode: ((Int) -> Bool)?

    private var tasks = [URL: URLSessionTask]()

    // MARK: - Functions

    /// 필수 델리게이트 메서드만 구현
    public func urlSession(
        _: URLSession,
        task _: URLSessionTask,
        didReceive challenge: URLAuthenticationChallenge
    ) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        await onReceiveChallenge?(challenge) ?? (.performDefaultHandling, nil)
    }

    public func urlSession(
        _: URLSession,
        dataTask _: URLSessionDataTask,
        didReceive response: URLResponse
    ) async -> URLSession.ResponseDisposition {
        guard let httpResponse = response as? HTTPURLResponse,
              onValidateStatusCode?(httpResponse.statusCode) == true else {
            return .cancel
        }
        return .allow
    }

    func cancelTasks(for url: URL) {
        tasks[url]?.cancel()
        tasks[url] = nil
    }

    func cancelAllTasks() {
        tasks.values.forEach { $0.cancel() }
        tasks.removeAll()
    }
}
