import Foundation

/// 프로젝트에 단일로 존재하며, 이미지 다운로드 URL과 SessionDataTask를 관리합니다.
@objc(NeoImageDelegate)
public actor SessionDelegate: NSObject {
    // MARK: - Properties

    var authenticationChallengeHandler: ((URLAuthenticationChallenge) async -> (
        URLSession.AuthChallengeDisposition,
        URLCredential?
    ))?

    private var tasks: [URL: SessionDataTask] = [:]

    // MARK: - Functions

    func add(_ dataTask: URLSessionDataTask, url: URL) async -> DownloadTask {
        let task = SessionDataTask(task: dataTask)
        var index = -1

        Task {
            index = await task.addDownloadTask()
            await task.resume()
        }

        tasks[url] = task
        return DownloadTask(sessionTask: task, index: index)
    }

    /// 기존 작업에 새 토큰 추가
    func append(_ task: SessionDataTask) async -> DownloadTask {
        var index = -1

        Task {
            index = await task.addDownloadTask()
        }

        return DownloadTask(sessionTask: task, index: index)
    }

    /// URL에 해당하는 SessionDataTask 반환
    func task(for url: URL) -> SessionDataTask? {
        tasks[url]
    }

    /// 작업 제거
    func removeTask(_ task: SessionDataTask) {
        guard let url = task.originalURL else {
            return
        }
        tasks[url] = nil
    }

    func cancelAll() {
        let taskValues = tasks.values
        for task in taskValues {
            Task {
                await task.forceCancel()
            }
        }
    }

    func cancel(url: URL) {
        Task {
            if let task = tasks[url] {
                await task.forceCancel()
            }
        }
    }

    private func cancelTask(_ dataTask: URLSessionDataTask) {
        dataTask.cancel()
    }

    private func remove(_ task: SessionDataTask) {
        guard let url = task.originalURL else {
            return
        }
        tasks[url] = nil
    }

    /// SessionDelegate.onCompleted에 사용
    private func task(for task: URLSessionTask) -> SessionDataTask? {
        guard let url = task.originalRequest?.url,
              let sessionTask = tasks[url],
              sessionTask.task.taskIdentifier == task.taskIdentifier else {
            return nil
        }

        return sessionTask
    }
}

// MARK: - URLSessionDataDelegate

/// 각 작업의 상태(ready, running, completed, failed, cancelled)를 세밀하게 추적하기 위해 Delegate 메서드 사용이 필요합니다.
extension SessionDelegate: URLSessionDataDelegate {
    public func urlSession(
        _: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse
    ) async -> URLSession.ResponseDisposition {
        guard response is HTTPURLResponse else {
            Task {
                taskCompleted(
                    dataTask,
                    with: nil,
                    error: NeoImageError
                        .responseError(
                            reason: .networkError(description: "Invalid HTTP Status Code")
                        )
                )
            }
            return .cancel
        }

        return .allow
    }

    public nonisolated func urlSession(
        _: URLSession,
        dataTask: URLSessionDataTask,
        didReceive data: Data
    ) {
        Task {
            guard let task = await self.task(for: dataTask) else {
                return
            }

            await task.didReceiveData(data)
        }
    }

    /// Actor-isolated instance method 'urlSession(_:task:didCompleteWithError:)' cannot be @objc
    /// Swift의 actor와 Objective-C 런타입 간 호환성 문제에 발생하는 컴파일 에러입니다.
    /// URLSessionDelegate 메서드들은 모두 Objective-C 런타임을 통해 호출되기에 프로토콜을 구현하는 메서드는 @objc로 노출되어야 합니다.
    /// SessionDelegate 클래스는 actor로 선언되어있기에 actor-isolated입니다. 이는 비동기적으로 실행되어야 합니다.
    /// 하지만 Objective-C는 Swift의 async/await의 actor 모델을 이해하지 못하기에 에러가 발생합니다.
    public nonisolated func urlSession(
        _: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        // SessionDataTask가 actor로 마이그레이션 되면서, 내부 didComplete 메서드는 비동기 컨텍스트에서 실행되어야 합니다.
        // Actor-isolated instance method 'urlSession(_:task:didCompleteWithError:)' cannot be @objc
        Task {
            guard let sessionTask = await self.task(for: task) else {
                return
            }

            await taskCompleted(task, with: sessionTask.mutableData, error: error)
        }
    }

    public func urlSession(
        _: URLSession,
        task _: URLSessionTask,
        didReceive challenge: URLAuthenticationChallenge
    ) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        if let handler = authenticationChallengeHandler {
            return await handler(challenge)
        }

        return (.performDefaultHandling, nil)
    }

    // MARK: - 헬퍼 메서드

    private func taskCompleted(_ task: URLSessionTask, with data: Data?, error: Error?) {
        Task {
            guard let sessionTask = self.task(for: task) else {
                return
            }

            let result: Result<(Data, URLResponse?), Error>
            if let error {
                result = .failure(
                    NeoImageError
                        .responseError(reason: .networkError(
                            description: error
                                .localizedDescription
                        ))
                )
            } else if let data {
                result = .success((data, task.response))
            } else {
                result = .failure(NeoImageError.responseError(reason: .invalidImageData))
            }

            await sessionTask.complete(with: result)

            // 작업 상태에 따라 맵에서 제거 (다운로드 성공 또는 모든 태스크가 취소됨)
            if await !sessionTask.hasActiveDownloadTask {
                remove(sessionTask)
            }
        }
    }
}
