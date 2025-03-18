import Foundation
import OSLog

/// 로깅 엔진의 싱글톤 래퍼 클래스
/// 스레드 안전성 및 FIFO 순서대로 작업됨을 보장하기 위해 시리얼 큐를 사용하여 로깅 작업을 처리합니다.
final class LogEngineWrapper: @unchecked Sendable {
    // MARK: - Static Properties

    /// 공유 인스턴스
    public static let shared = LogEngineWrapper()

    // MARK: - Properties
    
    /// 로깅 작업을 직렬화하기 위한 시리얼 큐
    private let queue = DispatchQueue(label: "com.bookKitty.logkit.serial", qos: .utility)

    /// 실제 로깅 작업을 수행하는 엔진 인스턴스
    private let logEngine = LogEngine()
    
    private init() {}

    // MARK: - Functions

    /// 로그를 기록하는 메인 메서드
    /// - Parameters:
    ///   - level: 로그 레벨
    ///   - message: 로그 메시지
    ///   - subSystem: 로그 서브시스템 (기본값: .app)
    ///   - category: 로그 카테고리 (기본값: .general)
    ///   - file: 로그가 발생한 파일
    ///   - function: 로그가 발생한 함수
    ///   - line: 로그가 발생한 라인 번호
    public func log(
        _ level: LogLevel,
        message: String,
        subSystem: LogSubSystem = .app,
        category: LogCategory = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        queue.async {
            self.logEngine.log(
                level,
                message: message,
                subSystem: subSystem,
                category: category,
                file: file,
                function: function,
                line: line
            )
        }
    }
}
