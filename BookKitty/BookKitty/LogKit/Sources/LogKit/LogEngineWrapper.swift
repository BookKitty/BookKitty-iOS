import Foundation
import OSLog

/// 로거를 식별하기 위한 키 구조체
struct LoggerKey: Hashable {
    let subSystem: LogSubSystem
    let category: LogCategory
}

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

/// 실제 로깅 작업을 수행하는 엔진 클래스
final class LogEngine {
    // MARK: - Properties

    /// 로그 타임스탬프 포맷팅을 위한 DateFormatter
    private let dateFormatter: DateFormatter
    
    /// 파일 연산을 위한 FileManager 인스턴스
    private let fileManager: FileManager
    
    /// 서브시스템과 카테고리별 로거 캐시
    private var loggers: [LoggerKey: Logger] = [:]

    /// 로그 엔진 시작 시간 문자열
    private let logEngineStartTime: String
    
    /// 현재 CSV 파일 ID
    private var currentCSVFileID = 1
    
    /// 현재 CSV 파일 URL
    private var currentCSVFileURL: URL?
    
    /// 현재 CSV 파일 크기
    private var currentCSVFileSize: UInt64 = 0
    
    /// 최대 CSV 파일 크기 (60KB)
    private let maxCSVFileSize: UInt64 = 60 * 1024

    // MARK: - Lifecycle

    init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"

        fileManager = FileManager.default

        let startTimeFormatter = DateFormatter()
        startTimeFormatter.dateFormat = "yyyyMMdd_HHmm"
        logEngineStartTime = startTimeFormatter.string(from: Date())

        initializeLoggers()
        createNewCSVFile()
    }

    // MARK: - Functions

    // MARK: - Public Methods

    func log(
        _ level: LogLevel,
        message: String,
        subSystem: LogSubSystem = .app,
        category: LogCategory = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let fileName = (file as NSString).lastPathComponent

        let logger = getLogger(subSystem: subSystem, category: category)
        logger.log(level: level.osLogType, "[\(fileName):\(line)] \(function) - \(message)")

        let timestamp = dateFormatter.string(from: Date())

        // CSV 로그 추가
        writeToCSVFile(
            timestamp: timestamp,
            level: level.rawValue,
            fileName: fileName,
            line: String(line),
            function: function,
            message: message,
            subSystem: subSystem.rawValue,
            category: category.rawValue
        )
    }

    // MARK: - Private Methods

    private func initializeLoggers() {
        var map: [LoggerKey: Logger] = [:]

        for subSystem in LogSubSystem.allCases {
            for category in LogCategory.allCases {
                let logger = Logger(subsystem: subSystem.rawValue, category: category.rawValue)
                map[LoggerKey(subSystem: subSystem, category: category)] = logger
            }
        }

        loggers = map
    }

    private func getLogger(subSystem: LogSubSystem, category: LogCategory) -> Logger {
        let key = LoggerKey(subSystem: subSystem, category: category)

        if let logger = loggers[key] {
            return logger
        } else {
            return Logger(subsystem: subSystem.rawValue, category: category.rawValue)
        }
    }

    private func createNewCSVFile() {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "\(logEngineStartTime)-\(currentCSVFileID).csv"
        let fileURL = documentsPath.appendingPathComponent(fileName)

        // CSV 헤더 생성
        let headerRow = "Timestamp,Level,FileName,Line,Function,Message,SubSystem,Category\n"

        do {
            try headerRow.write(to: fileURL, atomically: true, encoding: .utf8)
            currentCSVFileURL = fileURL
            currentCSVFileSize = UInt64(headerRow.utf8.count)
            print("새 CSV 로그 파일이 생성되었습니다: \(fileName)")
        } catch {
            print("CSV 로그 파일 생성 실패: \(error)")
        }
    }

    private func writeToCSVFile(
        timestamp: String,
        level: String,
        fileName: String,
        line: String,
        function: String,
        message: String,
        subSystem: String,
        category: String
    ) {
        let escapedMessage = message.replacingOccurrences(of: "\"", with: "\"\"")
        let escapedFunction = function.replacingOccurrences(of: "\"", with: "\"\"")

        // CSV 행 생성
        let csvRow =
            "\"\(timestamp)\",\"\(level)\",\"\(fileName)\",\"\(line)\",\"\(escapedFunction)\",\"\(escapedMessage)\",\"\(subSystem)\",\"\(category)\"\n"

        guard let csvData = csvRow.data(using: .utf8) else {
            return
        }
        let dataSize = UInt64(csvData.count)

        // 현재 파일이 최대 크기를 초과하는지 확인
        if currentCSVFileSize + dataSize > maxCSVFileSize {
            currentCSVFileID += 1
            createNewCSVFile()
        }

        // CSV 파일에 로그 추가
        guard let fileURL = currentCSVFileURL else {
            return
        }

        if let fileHandle = try? FileHandle(forWritingTo: fileURL) {
            fileHandle.seekToEndOfFile()
            fileHandle.write(csvData)
            try? fileHandle.close()

            currentCSVFileSize += dataSize
        }
    }
}
