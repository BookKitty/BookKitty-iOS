import Foundation

/// 이미지 다운로드 작업의 상태를 나타내는 열거형
public enum ImageTaskState: Int, Sendable {
    /// 대기 중
    case pending = 0
    /// 다운로드 중
    case downloading
    /// 취소됨
    case cancelled
    /// 완료됨
    case completed
    /// 실패
    case failed
}

/// 이미지 다운로드 작업을 관리하는 클래스
public final class ImageTask: @unchecked Sendable {
    
    // MARK: - Properties
    
    /// 현재 작업의 상태
    @ImageCacheActor
    public private(set) var state: ImageTaskState = .pending
    
    /// 다운로드 진행률
    @ImageCacheActor
    public private(set) var progress: Float = 0
    
    /// 작업 시작 시간
    @ImageCacheActor
    public private(set) var startTime: Date?
    
    /// 작업 완료 시간
    @ImageCacheActor
    public private(set) var endTime: Date?
    
    /// 취소 여부
    @ImageCacheActor
    public private(set) var isCancelled: Bool = false
    
    /// 다운로드된 데이터 크기
    @ImageCacheActor
    public private(set) var downloadedDataSize: Int64 = 0
    
    /// 전체 데이터 크기
    @ImageCacheActor
    public private(set) var totalDataSize: Int64 = 0
    
    // MARK: - Initializer
    
    public init() {}
    
    // MARK: - Public Methods
    
    /// 작업 취소
    @ImageCacheActor
    public func cancel() {
        guard state == .pending || state == .downloading else { return }
        state = .cancelled
        isCancelled = true
        endTime = Date()
    }
    
    /// 작업 시작
    @ImageCacheActor
    public func start() {
        guard state == .pending else { return }
        state = .downloading
        startTime = Date()
    }
    
    /// 작업 완료
    @ImageCacheActor
    public func complete() {
        guard state == .downloading else { return }
        state = .completed
        endTime = Date()
    }
    
    /// 작업 실패
    @ImageCacheActor
    public func fail() {
        guard state != .completed && state != .cancelled else { return }
        state = .failed
        endTime = Date()
    }
    
    /// 진행률 업데이트
    @ImageCacheActor
    public func updateProgress(downloaded: Int64, total: Int64) {
        downloadedDataSize = downloaded
        totalDataSize = total
        progress = total > 0 ? Float(downloaded) / Float(total) : 0
    }
}

// MARK: - CustomStringConvertible

extension ImageTask: CustomStringConvertible {
    public var description: String {
//        "ImageTask(state: \(state), progress: \(progress))"
        "ImageTask(state, progress: )"
    }
}

// MARK: - Hashable

extension ImageTask: Hashable {
    public static func == (lhs: ImageTask, rhs: ImageTask) -> Bool {
        ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

// MARK: - Convenience Properties

extension ImageTask {
    /// 작업 소요 시간 (밀리초)
    @ImageCacheActor
    public var duration: TimeInterval? {
        guard let start = startTime else { return nil }
        let end = endTime ?? Date()
        return end.timeIntervalSince(start)
    }
    
    /// 다운로드 속도 (bytes/second)
    @ImageCacheActor
    public var downloadSpeed: Double? {
        guard let duration = duration, duration > 0 else { return nil }
        return Double(downloadedDataSize) / duration
    }
}
