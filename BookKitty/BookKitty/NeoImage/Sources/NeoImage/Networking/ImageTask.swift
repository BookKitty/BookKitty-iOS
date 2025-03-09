import Foundation

/// 이미지 작업을 나타내는 클래스로, 취소 기능을 제공합니다.
public final actor ImageTask {
    // MARK: - Properties

    private var downloadTask: DownloadTask?
    private var isCancelled = false

    // MARK: - Lifecycle

    public init() {}

    // MARK: - Functions

    /// 작업을 취소합니다.
    public func cancel() async {
        isCancelled = true
        await downloadTask?.cancel()
    }

    /// 작업이 실패했음을 표시합니다.
    public func fail() async {
        isCancelled = true
    }

    /// 다운로드 작업을 설정합니다.
    public func setDownloadTask(_ task: DownloadTask) {
        downloadTask = task
    }
}
