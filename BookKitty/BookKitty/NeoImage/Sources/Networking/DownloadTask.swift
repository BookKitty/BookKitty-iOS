import Foundation

public final actor DownloadTask: Sendable {
    // MARK: - Properties

    private(set) var sessionTask: SessionDataTask?
    private(set) var index: Int?

    // MARK: - Lifecycle

    init(
        sessionTask: SessionDataTask? = nil,
        index: Int? = nil
    ) {
        self.sessionTask = sessionTask
        self.index = index
    }

    // MARK: - Functions

    /// 이 다운로드 작업이 실행 중인 경우 취소합니다.
    public func cancelWithError() async throws {
        guard let sessionTask, let index else {
            return
        }

        await sessionTask.cancel(index: index)

        throw NeoImageError.responseError(reason: .cancelled)
    }

    public func cancel() async {
        guard let sessionTask, let index else {
            return
        }

        await sessionTask.cancel(index: index)
    }

    func linkToTask(_ task: DownloadTask) {
        Task {
            self.sessionTask = await task.sessionTask
            self.index = await task.index
        }
    }
}
