import Foundation

/// `ImageDownloader`에서 사용되는 세션 데이터 작업을 나타냅니다.
///
/// 기본적으로 `SessionDataTask`는 `URLSessionDataTask`를 래핑하고 다운로드 데이터를 관리합니다.
/// `SessionDataTask/CancelToken`을 사용하여 작업을 추적하고 취소를 관리합니다.
public class SessionDataTask: @unchecked Sendable {
    // MARK: - Nested Types

    /// 작업을 취소하는 데 사용되는 토큰 타입입니다.
    public typealias CancelToken = Int

    /// 작업 콜백을 나타내는 구조체입니다.
    struct TaskCallback {
        let onCompleted: Delegate<
            Result<ImageLoadingResult, NeoImageError>,
            Void
        >? // 작업 완료 시 호출될 콜백
    }

    // MARK: - Properties

    // `task.originalRequest?.url`의 복사본입니다. iOS 13에서 발생할 수 있는 레이스 컨디션을 방지하기 위해 사용됩니다.
    // 참고: https://github.com/onevcat/Kingfisher/issues/1511
    public let originalURL: URL?

    /// 내부적으로 사용되는 다운로드 작업입니다.
    ///
    /// 이 작업은 오류가 발생했을 때 디버깅 목적으로만 사용됩니다. 이 작업의 내용을 수정하거나 직접 시작해서는 안 됩니다.
    public let task: URLSessionDataTask

    /// 작업이 완료되었을 때 호출될 델리게이트입니다.
    /// `클래스 내부에는 델리게이트 선언만 진행하고, 등록은 ImageDownloader의 createDownloadTask 메서드에서 진행합니다.`
    let onTaskDone = Delegate<(Result<(Data, URLResponse?), NeoImageError>, [TaskCallback]), Void>()
    /// 콜백이 취소되었을 때 호출될 델리게이트입니다.
    let onCallbackCancelled = Delegate<(CancelToken, TaskCallback), Void>()

    var started = false // 작업이 시작되었는지 여부를 나타냄

    private var _mutableData: Data // 다운로드된 데이터를 저장하는 변수
    private var callbacksStore = [CancelToken: TaskCallback]() // 콜백을 저장하는 딕셔너리

    private var currentToken = 0 // 콜백을 식별하기 위한 고유 토큰
    private let lock = NSLock() // 스레드 안전성을 위한 lock

    // MARK: - Computed Properties

    // 현재 작업에서 다운로드된 원시 데이터입니다.

    /// ImageCache와 같은 공유 클래스에서 DispatchQueue를 사용한 것과 달리, locking 매커니즘을 사용하고 있습니다.
    /// 이는 DispatchQueue를 사용한 동기화는 간편하지만, 큐에 작업을 넣고 실행하는 오버헤드가 있기 때문입니다.
    /// 작은 청크로 자주 도착하는 네트워크 데이터의 경우, 빈번하고 짧은 연산이기에 직접적인 locking 매커니즘을 택하는 것이 더 적은 오버헤드로 이어집니다.
    public var mutableData: Data {
        lock.lock()
        defer { lock.unlock() }
        return _mutableData // 스레드 안전성을 위해 lock을 사용하여 데이터 접근
    }

    /// 다운로드가 완료되었을 때
    /// 다운로드 중 오류가 발생했을 때
    /// 다운로드 진행 상태가 업데이트되었을 때
    /// 위 이벤트 발생 시, 등록하여 매핑한 콜백이 호출
    var callbacks: [SessionDataTask.TaskCallback] {
        lock.lock()
        defer { lock.unlock() }
        return Array(callbacksStore.values) // 현재 등록된 모든 콜백을 반환
    }

    var containsCallbacks: Bool {
        // `task.state != .running`을 사용하여 확인할 수 있어야 하지만,
        // 드물게 작업을 취소해도 작업 상태가 즉시 `.cancelling`으로 변경되지 않고 `.running` 상태로 남아있는 경우가 있습니다.
        // 따라서 작업을 안전하게 제거하기 위해 콜백 개수를 확인합니다.
        !callbacks.isEmpty
    }

    // MARK: - Lifecycle

    /// `SessionDataTask`를 초기화합니다.
    init(task: URLSessionDataTask) {
        self.task = task
        originalURL = task.originalRequest?.url // 원본 URL을 저장
        _mutableData = Data() // 데이터 저장을 위한 빈 `Data` 객체 초기화
    }

    // MARK: - Functions

    /// 새로운 콜백을 추가하고 고유 토큰을 반환합니다.
    func addCallback(_ callback: TaskCallback) -> CancelToken {
        lock.lock()
        defer { lock.unlock() }
        callbacksStore[currentToken] = callback // 콜백을 딕셔너리에 저장
        defer { currentToken += 1 } // 토큰 값을 증가시킴
        // 종료되기 `직전에` 호출되는 defer 키워드를 사용해 addCallback이 정상적으로 종료될때에만 실행되도록 하여, 코드의 안정성을 높일 수 있음.
        return currentToken // 고유 토큰 반환
    }

    /// 특정 토큰에 해당하는 콜백을 제거하고 반환합니다.
    /// 다운로드 작업의 중단 및 리소스 관리 관련 상황에서 호출됩니다.
    /// 일일히 제거하는 이유는 불필요한 메모리 사용을 줄이는 것도 있지만, 추후 메모리 누수가 발생할 수도 있기 때문
    func removeCallback(_ token: CancelToken) -> TaskCallback? {
        lock.lock()
        defer { lock.unlock() }
        if let callback = callbacksStore[token] {
            callbacksStore[token] = nil // 콜백 제거
            return callback // 제거된 콜백 반환
        }
        return nil // 해당 토큰에 대한 콜백이 없을 경우 nil 반환
    }

    /// 모든 콜백을 제거하고 제거된 콜백 목록을 반환합니다.
    @discardableResult
    func removeAllCallbacks() -> [TaskCallback] {
        lock.lock()
        defer { lock.unlock() }
        let callbacks = callbacksStore.values // 모든 콜백을 가져옴
        callbacksStore.removeAll() // 딕셔너리 비우기
        return Array(callbacks) // 제거된 콜백 목록 반환
    }

    /// 작업을 시작합니다.
    func resume() {
        guard !started else {
            return
        } // 이미 시작된 작업은 다시 시작하지 않음
        started = true // 작업 상태를 시작됨으로 표시
        task.resume() // 내부 `URLSessionDataTask` 시작
    }

    /// 특정 토큰에 해당하는 작업을 취소합니다.
    func cancel(token: CancelToken) {
        guard let callback = removeCallback(token) else {
            return // 해당 토큰에 대한 콜백이 없을 경우 종료
        }

        // removeCallback과 같이 직접적인 잠금 매커니즘이 적용되지 않았음에도, 사용하는 Delegate 객체들이 이미 내부적으로 스레드 안정성을 보장하고
        // 있음.
        onCallbackCancelled.call((token, callback)) // 콜백 취소 이벤트 호출
    }

    /// 모든 콜백을 강제로 취소합니다.
    func forceCancel() {
        for token in callbacksStore.keys {
            cancel(token: token) // 모든 토큰에 대해 취소 작업 수행
        }
    }

    /// 데이터를 수신하고 저장합니다.
    func didReceiveData(_ data: Data) {
        lock.lock()
        defer { lock.unlock() }
        _mutableData.append(data) // 수신된 데이터를 기존 데이터에 추가
    }
}
