//
//  LogEngine.swift
//  LogKit
//
//  Created by 권승용 on 3/18/25.
//

import OSLog
import Foundation

/// 로거를 식별하기 위한 키 구조체
struct LoggerKey: Hashable {
    let subSystem: LogSubSystem
    let category: LogCategory
}

/// 실제 로깅 작업을 수행하는 엔진 클래스
final class LogEngine {
    // MARK: - Properties
    
    /// 서브시스템과 카테고리별 로거 캐시
    private var loggers: [LoggerKey: Logger] = [:]

    /// 로그 타임스탬프 포맷팅을 위한 DateFormatter
    private let dateFormatter: DateFormatter

    private let fileWritingService: FileWritingService
    
    // MARK: - Lifecycle

    init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        
        fileWritingService = FileWritingService()
        initializeLoggers()
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
        fileWritingService.writeToCSVFile(
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
}
