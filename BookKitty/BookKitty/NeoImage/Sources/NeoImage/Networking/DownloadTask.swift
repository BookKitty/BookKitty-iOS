import Foundation

public final actor DownloadTask: Sendable {
    // MARK: - Properties

    private(set) var sessionTask: SessionDataTask?
    private(set) var cancelToken: SessionDataTask.CancelToken?

    // MARK: - Computed Properties

    /// DownloadTask가 제대로 초기화되었는지 확인하는 메서드
    public var isInitialized: Bool {
        sessionTask != nil && cancelToken != nil
    }

    // MARK: - Lifecycle

    init(
        sessionTask: SessionDataTask? = nil,
        cancelToken: SessionDataTask.CancelToken? = nil
    ) {
        self.sessionTask = sessionTask
        self.cancelToken = cancelToken
    }

    // MARK: - Functions

    /// Cancel this single download task if it is running.
    public func cancel() {
        guard let sessionTask, let cancelToken else {
            return
        }
        sessionTask.cancel(token: cancelToken)
    }

    /// 다른 DownloadTask의 sessionTask와 cancelToken을 이 DownloadTask에 연결
    func linkToTask(_ task: DownloadTask) {
        Task {
            guard await task.isInitialized else {
                return
            }
            await sessionTask = task.sessionTask
            await cancelToken = task.cancelToken
        }
    }
}
