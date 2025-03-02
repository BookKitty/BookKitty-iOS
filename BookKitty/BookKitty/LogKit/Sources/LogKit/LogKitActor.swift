import Foundation
import OSLog

struct LoggerKey: Hashable {
    let subSystem: LogSubSystem
    let category: LogCategory
}

/// 단순히 전역 액터 속성만 정의
@globalActor
public actor LogKitActor {
    public static let shared = LogKitActor()
}

public final class _LogKit {
    // MARK: - Static Properties
    /// @globalActor를 사용해 shared 인스턴스에만 격리 도메인을 지정하는 것은 동시성 격리를 부분적으로 선택적으로 적용
    /// 어떤 부분이 격리되어야 하고 어떤 부분이 일반 동기 코드로 실행되어도 되는지 더 세밀하게 제어
    /// 실제로 모든 코드가 항상 격리될 필요는 없기 때문에 성능상 이점도 존재
    /// 공유 자원에 대한 접근은 조정해야 하지만, 모든 기능이 액터 내부에 있을 필요는 없는 경우 적합
    @LogKitActor
    static let shared = _LogKit()
    
    /// logger 인스턴스를 생성하는 로직을 초기화기 내부에서 호출 하는 것은 actor 내에 actor-isolated 메서드를 동기적으로(synchronous)
    /// 호출하는 것입니다.
    /// Actor의 초기화 과정에서는 actor의 격리 매커니즘이 완전히 설정되지 않았기 때문에 actor-isolated 메서드를 직접 호출할 수 없습니다.
    /// `actor는 공유 가변 상태에 대한 안전한 접근을 보장하기 위한 동시성 타입`
    /// 이를 위해 actor 내부 모든 메서드와 프로퍼티는 기본적으로 actor-isolated 되어있기에, actor 외부에선 await 키워드와 함께 호출되어야 하며,
    /// 동시에 외부에서 호출되더라도 자동으로 직렬화됩니다.
    ///
    /// 각 카테고리에 해당한느 로거 인스턴스를 Actor 속성이 아닌, 정적 속성으로 생성
    /// static 프로퍼티 및 메서드는 인스턴스와 무관하게 타입 자체에 속하기에 actor의 격리 메커니즘 밖에 존재하여, actor-isolation 제약을 받지 않게
    /// 됨.
    private static let loggers: [LoggerKey: Logger] = {
        var map: [LoggerKey: Logger] = [:]
        
        for subSystem in LogSubSystem.allCases {
            for category in LogCategory.allCases {
                let logger = Logger(subsystem: subSystem.rawValue, category: category.rawValue)
                map[LoggerKey(subSystem: subSystem, category: category)] = logger
            }
        }
        
        return map
    }()
    
    private let dateFormatter: DateFormatter
    private let fileManager: FileManager
    
    private let appStartTime: String
    private var currentCSVFileID: Int = 1
    private var currentCSVFileURL: URL?
    private var currentCSVFileSize: UInt64 = 0
    private let maxCSVFileSize: UInt64 = 6 * 1024  // 6KB size limit
    
    // MARK: - Lifecycle
    
    private init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        
        fileManager = FileManager.default
        
        let startTimeFormatter = DateFormatter()
        startTimeFormatter.dateFormat = "yyyyMMdd_HHmm"
        appStartTime = startTimeFormatter.string(from: Date())
        
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
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
    ) async {
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
    
    private func getLogger(subSystem: LogSubSystem, category: LogCategory) -> Logger {
        let key = LoggerKey(subSystem: subSystem, category: category)
        
        if let logger = _LogKit.loggers[key] {
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
    
    private func writeToCSVFile(timestamp: String, level: String, fileName: String, line: String, function: String, message: String, subSystem: String, category: String) {
        let escapedMessage = message.replacingOccurrences(of: "\"", with: "\"\"")
        let escapedFunction = function.replacingOccurrences(of: "\"", with: "\"\"")
        
        // CSV 행 생성
        let csvRow = "\"\(timestamp)\",\"\(level)\",\"\(fileName)\",\"\(line)\",\"\(escapedFunction)\",\"\(escapedMessage)\",\"\(subSystem)\",\"\(category)\"\n"
        
        guard let csvData = csvRow.data(using: .utf8) else { return }
        let dataSize = UInt64(csvData.count)
        
        // 현재 파일이 최대 크기를 초과하는지 확인
        if currentCSVFileSize + dataSize > maxCSVFileSize {
            currentCSVFileID += 1
            createNewCSVFile()
        }
        
        // CSV 파일에 로그 추가
        guard let fileURL = currentCSVFileURL else { return }
        
        if let fileHandle = try? FileHandle(forWritingTo: fileURL) {
            fileHandle.seekToEndOfFile()
            fileHandle.write(csvData)
            try? fileHandle.close()
            
            currentCSVFileSize += dataSize
        }
    }
}
