import Foundation
import OSLog

struct LoggerKey: Hashable {
    let subSystem: LogSubSystem
    let category: LogCategory
}

/// 단순히 전역 액터 속성만 정의하는 것이 아니라, 로깅 인터페이스도 제공
@globalActor
public actor LogKitActor {
    // MARK: - Static Properties

    public static let shared = LogKitActor()

    // MARK: - Properties

    /// _LogKit의 인스턴스를 직접 관리
    private let logKit = _LogKit()

    // MARK: - Functions

    /// _LogKit의 메서드를 액터 내부에서 호출
    public func log(
        _ level: LogLevel,
        message: String,
        subSystem: LogSubSystem = .app,
        category: LogCategory = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        // 액터 내부에서는 await 없이 동기적으로 호출 가능
        logKit.log(
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

final class _LogKit {
    // MARK: - Properties

    /// @globalActor를 사용해 shared 인스턴스에만 격리 도메인을 지정하는 것은 동시성 격리를 부분적으로 선택적으로 적용
    /// 어떤 부분이 격리되어야 하고 어떤 부분이 일반 동기 코드로 실행되어도 되는지 더 세밀하게 제어
    /// 실제로 모든 코드가 항상 격리될 필요는 없기 때문에 성능상 이점도 존재
    /// 공유 자원에 대한 접근은 조정해야 하지만, 모든 기능이 액터 내부에 있을 필요는 없는 경우 적합
    private let dateFormatter: DateFormatter
    private let fileManager: FileManager
    private var loggers: [LoggerKey: Logger] = [:]

    private let appStartTime: String
    private var currentCSVFileID = 1
    private var currentCSVFileURL: URL?
    private var currentCSVFileSize: UInt64 = 0
    private let maxCSVFileSize: UInt64 = 60 * 1024 // 60KB

    // MARK: - Lifecycle

    init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"

        fileManager = FileManager.default

        let startTimeFormatter = DateFormatter()
        startTimeFormatter.dateFormat = "yyyyMMdd_HHmm"
        appStartTime = startTimeFormatter.string(from: Date())

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
        let fileName = "\(appStartTime)-\(currentCSVFileID).csv"
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
