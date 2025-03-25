import Foundation

/// `ImageDownloader`에서 사용되는 세션 데이터 작업을 나타냅니다.
/// 기본적으로 `SessionDataTask`는 `URLSessionDataTask`를 래핑하고 다운로드 데이터를 관리합니다.
/// `SessionDataTask/CancelToken`을 사용하여 작업을 추적하고 취소를 관리합니다.
public actor SessionDataTask {
    // MARK: - Properties

    public let originalURL: URL?

    let task: URLSessionDataTask
    let onCallbackTaskDone = Delegate<(Result<(Data, URLResponse?), Error>, Bool), Void>()

    private(set) var taskResult: Result<(Data, URLResponse?), Error>?
    private(set) var isCompleted = false

    private(set) var mutableData: Data

    private var DownloadTaskIndices = Set<Int>()
    private var currentIndex = 0

    // MARK: - Lifecycle

    init(task: URLSessionDataTask) {
        self.task = task
        mutableData = Data()
        originalURL = task.originalRequest?.url

        NeoLogger.shared.info("initialized")
    }

    // MARK: - Functions

    func didReceiveData(_ data: Data) {
        mutableData.append(data)
    }

    func resume() {
        task.resume()
    }

    func complete(with result: Result<(Data, URLResponse?), Error>) {
        taskResult = result
        isCompleted = true

        Task {
            await onCallbackTaskDone((result, true))
        }
    }
}

extension SessionDataTask {
    func addDownloadTask() -> Int {
        let index = currentIndex
        DownloadTaskIndices.insert(index)
        currentIndex += 1
        return index
    }

    func removeDownloadTask(_ index: Int) -> Bool {
        DownloadTaskIndices.remove(index) != nil
    }

    var hasActiveDownloadTask: Bool {
        !DownloadTaskIndices.isEmpty
    }

    func cancel(index: Int) {
        if removeDownloadTask(index), !hasActiveDownloadTask {
            // 모든 토큰이 취소되었을 때만 실제 작업 취소
            task.cancel()
        }
    }

    func forceCancel() {
        DownloadTaskIndices.removeAll()
        task.cancel()
    }
}
