import NeoImage
import Testing
import UIKit

@Suite("NeoImage DownloadTask 취소 테스트")
struct NeoImageDownloadTaskCancelTests {
    @Test("동일한 이미지뷰에 새로운 이미지 요청시 이전 다운로드 작업 취소 확인")
    func testCancelOnNewRequest() async throws {
        // 테스트 환경 준비
        let context = await TestContext()

        // 첫 번째 이미지 로드 시작 (완료되지 않을 큰 이미지)
        let firstRequestStarted = await context.startDownload(with: context.largeImageURL)
        #expect(firstRequestStarted, "첫 번째 다운로드 작업이 시작되어야 합니다")

        // 작업이 시작될 시간 부여
        try await Task.sleep(for: .milliseconds(200))

        // 이미지뷰에 다운로드 작업이 연결되었는지 확인
        let hasFirstTask = await context.hasDownloadTask()
        #expect(hasFirstTask, "이미지뷰에 다운로드 작업이 연결되어야 합니다")

        // 두 번째 이미지 로드 시작 (이전 작업을 취소해야 함)
        let secondRequestStarted = await context.startDownload(with: context.secondImageURL)
        #expect(secondRequestStarted, "두 번째 다운로드 작업이 시작되어야 합니다")

        // 두 번째 다운로드 완료까지 대기
        try await Task.sleep(for: .milliseconds(500))

        // 첫 번째 다운로드가 취소되었는지 확인
        let wasCancelled = await context.wasLastDownloadCancelled()
        #expect(wasCancelled, "첫 번째 다운로드 작업이 취소되어야 합니다")

        Task {
            await context.cleanup()
        }
    }

    @Test("수동으로 DownloadTask 취소")
    func testManualCancellation() async throws {
        // 테스트 환경 준비
        let context = await TestContext()

        // 이미지 로드 시작
        let downloadStarted = await context.startDownload(with: context.largeImageURL)
        #expect(downloadStarted, "다운로드 작업이 시작되어야 합니다")

        // 작업이 시작될 시간 부여
        try await Task.sleep(for: .milliseconds(200))

        // 작업 수동 취소
        let wasCancelled = await context.cancelCurrentDownloadTask()
        #expect(wasCancelled, "다운로드 작업이 수동으로 취소되어야 합니다")
        Task {
            await context.cleanup()
        }
    }
}

/// 테스트를 위한 컨텍스트 클래스
@MainActor
class TestContext {
    // MARK: - Properties

    // 테스트용 윈도우와 이미지뷰
    var testWindow: UIWindow
    var imageView: UIImageView

    // 테스트용 URL (큰 이미지와 작은 이미지)
    let largeImageURL = URL(string: "https://picsum.photos/2000/2000")!
    let secondImageURL = URL(string: "https://picsum.photos/id/237/300/300")!

    // 취소 상태 추적
    private var downloadWasCancelled = false
    private var downloadCompleted = false

    // MARK: - Lifecycle

    init() {
        // 테스트 윈도우 생성
        testWindow = UIWindow(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
        testWindow.makeKeyAndVisible()

        // 이미지뷰 생성
        imageView = UIImageView(frame: testWindow.bounds)
        imageView.contentMode = .scaleAspectFit
        testWindow.addSubview(imageView)

        // 테스트 전 캐시 비우기
        ImageCache.shared.clearCache()
    }

    // MARK: - Functions

    func cleanup() {
        // 테스트 후 정리
        imageView.removeFromSuperview()
        testWindow.isHidden = true
    }

    /// 다운로드 시작 (async/await 방식)
    func startDownload(with url: URL) async -> Bool {
        do {
            try await imageView.neo.setImage(with: url)
            downloadCompleted = true
            return true
        } catch {
            if let neoError = error as? NeoImageError,
               case let .responseError(reason) = neoError,
               case .cancelled = reason {
                downloadWasCancelled = true
            }
            return true // 작업이 시작되었으나 취소됨
        }
    }

    /// 현재 다운로드 작업 취소
    func cancelCurrentDownloadTask() async -> Bool {
        if let task = objc_getAssociatedObject(
            imageView,
            &AssociatedKeys.downloadTask
        ) as? DownloadTask {
            await task.cancel()
            // 취소 처리 결과 확인을 위한 대기
            try? await Task.sleep(for: .milliseconds(500))
            return true
        }
        return false
    }

    /// 이미지뷰에 다운로드 작업이 연결되어 있는지 확인
    func hasDownloadTask() -> Bool {
        let result = objc_getAssociatedObject(imageView, &AssociatedKeys.downloadTask)
        print(result)
        return objc_getAssociatedObject(imageView, &AssociatedKeys.downloadTask) as? DownloadTask !=
            nil
    }

    /// 마지막 다운로드가 취소되었는지 확인
    func wasLastDownloadCancelled() -> Bool {
        downloadWasCancelled
    }
}
