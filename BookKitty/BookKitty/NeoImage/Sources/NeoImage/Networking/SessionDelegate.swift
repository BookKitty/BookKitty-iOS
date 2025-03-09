
import Foundation

@objc(NeoImageDelegate)
open class SessionDelegate: NSObject, @unchecked Sendable {
    // MARK: - Properties

    let onValidStatusCode = Delegate<Int, Bool>()
    let onReceiveChallenge = Delegate<
        URLAuthenticationChallenge,
        (URLSession.AuthChallengeDisposition, URLCredential?)
    >()
    let onDownloadingFinished = Delegate<(URL, Result<URLResponse, NeoImageError>), Void>()

    private var tasks: [URL: SessionDataTask] = [:]
    private let lock = NSLock()

    // MARK: - Functions

    /// Adds a new download task with a URL and callback
    func add(
        _ dataTask: URLSessionDataTask,
        url: URL,
        callback: SessionDataTask.TaskCallback
    ) -> DownloadTask {
        lock.lock()
        defer { lock.unlock() }

        let task = SessionDataTask(task: dataTask)

        task.onCallbackCancelled.delegate(on: self) { [weak task] (self, value) in
            guard let task else {
                return
            }

            let (token, callback) = value

            let error = NeoImageError.requestError(reason: .taskCancelled(task: task, token: token))
            task.onTaskDone.call((.failure(error), [callback]))

            // Remove the task if no other callbacks waiting
            if !task.containsCallbacks {
                let dataTask = task.task
                self.cancelTask(dataTask)
                self.remove(task)
            }
        }

        // Add callback and get token
        let token = task.addCallback(callback)
        tasks[url] = task

        return DownloadTask(sessionTask: task, cancelToken: token)
    }

    /// Appends a callback to an existing task and returns a new DownloadTask
    func append(
        _ task: SessionDataTask,
        callback: SessionDataTask.TaskCallback
    ) -> DownloadTask {
        let token = task.addCallback(callback)
        return DownloadTask(sessionTask: task, cancelToken: token)
    }

    /// Gets a task by URL
    func task(for url: URL) -> SessionDataTask? {
        lock.lock()
        defer { lock.unlock() }
        return tasks[url]
    }

    /// Cancels all tasks
    func cancelAll() {
        lock.lock()
        let taskValues = tasks.values
        lock.unlock()
        for task in taskValues {
            task.forceCancel()
        }
    }

    /// Cancels a task for a URL
    func cancel(url: URL) {
        lock.lock()
        let task = tasks[url]
        lock.unlock()
        task?.forceCancel()
    }

    /// Cancels a URLSessionDataTask
    private func cancelTask(_ dataTask: URLSessionDataTask) {
        lock.lock()
        defer { lock.unlock() }
        dataTask.cancel()
    }

    /// Removes a task
    private func remove(_ task: SessionDataTask) {
        lock.lock()
        defer { lock.unlock() }

        guard let url = task.originalURL else {
            return
        }

        task.removeAllCallbacks()
        tasks[url] = nil
    }

    /// Gets a task by URLSessionTask
    private func task(for task: URLSessionTask) -> SessionDataTask? {
        lock.lock()
        defer { lock.unlock() }

        guard let url = task.originalRequest?.url else {
            return nil
        }
        guard let sessionTask = tasks[url] else {
            return nil
        }
        guard sessionTask.task.taskIdentifier == task.taskIdentifier else {
            return nil
        }
        return sessionTask
    }
}

// MARK: - URLSessionDataDelegate

extension SessionDelegate: URLSessionDataDelegate {
    open func urlSession(
        _: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse
    ) async -> URLSession.ResponseDisposition {
        guard response is HTTPURLResponse else {
            let error = NeoImageError
                .responseError(reason: .URLSessionError(description: "invalid http Response"))
            onCompleted(task: dataTask, result: .failure(error))

            return .cancel
        }

        return .allow
    }

    open func urlSession(
        _: URLSession,
        dataTask: URLSessionDataTask,
        didReceive data: Data
    ) {
        guard let task = task(for: dataTask) else {
            return
        }

        task.didReceiveData(data)
    }

    open func urlSession(
        _: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: (any Error)?
    ) {
        guard let sessionTask = self.task(for: task) else {
            return
        }
        if let url = sessionTask.originalURL {
            let result: Result<URLResponse, NeoImageError>
            if let error {
                result = .failure(
                    NeoImageError
                        .responseError(reason: .URLSessionError(
                            description: error
                                .localizedDescription
                        ))
                )
            } else if let response = task.response {
                result = .success(response)
            } else {
                result = .failure(
                    NeoImageError
                        .responseError(reason: .URLSessionError(description: "no http Response"))
                )
            }

            onDownloadingFinished.call((url, result))
        }

        let result: Result<(Data, URLResponse?), NeoImageError>

        if let error {
            result = .failure(
                NeoImageError
                    .responseError(reason: .URLSessionError(
                        description: error
                            .localizedDescription
                    ))
            )
        } else {
            result = .success((sessionTask.mutableData, task.response))
        }

        onCompleted(task: task, result: result)
    }

    /// Called for task authentication challenge
    open func urlSession(
        _: URLSession,
        task _: URLSessionTask,
        didReceive challenge: URLAuthenticationChallenge
    ) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        onReceiveChallenge(challenge) ?? (.performDefaultHandling, nil)
    }

    private func onCompleted(
        task: URLSessionTask,
        result: Result<(Data, URLResponse?), NeoImageError>
    ) {
        // SessionDataTask 탐색
        guard let sessionTask = self.task(for: task) else {
            return
        }

        let finalResult: Result<(Data, URLResponse?), NeoImageError>

        if case .failure = result {
            finalResult = result
        } else {
            finalResult = .success((sessionTask.mutableData, task.response))
        }

        let callbacks = sessionTask.removeAllCallbacks()
        // 대응되는 SessionDataTask의 onTaskDone 델리게이트를 통해 결과 및 콜백 전달
        sessionTask.onTaskDone.call((finalResult, callbacks))

        remove(sessionTask)
    }
}
