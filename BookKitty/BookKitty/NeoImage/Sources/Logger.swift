import Foundation
import OSLog

public enum LogLevel: String {
    case debug = "DEBUG"
    case info = "INFO"
    case log = "LOG"
    case error = "ERROR"

    // MARK: - Computed Properties

    var osLogType: OSLogType {
        switch self {
        case .debug: return .debug
        case .info: return .info
        case .log: return .default
        case .error: return .error
        }
    }
}

final class NeoLogger: Sendable {
    // MARK: - Static Properties

    public static let shared = NeoLogger()

    // MARK: - Properties

    private let dateFormatter: DateFormatter

    private let logger: Logger

    private let infoHidden = true
    private let debugHidden = true

    // MARK: - Lifecycle

    init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        logger = Logger()
    }

    // MARK: - Functions

    public func error(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line _: Int = #line
    ) {
        log(
            .error,
            message: message,
            file: file,
            function: function
        )
    }

    public func info(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line _: Int = #line
    ) {
        guard !infoHidden else {
            return
        }

        log(
            .info,
            message: message,
            file: file,
            function: function
        )
    }

    public func debug(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line _: Int = #line
    ) {
        guard !debugHidden else {
            return
        }

        log(
            .debug,
            message: message,
            file: file,
            function: function
        )
    }
}

// MARK: - Private Methods

extension NeoLogger {
    private func log(
        _ level: LogLevel,
        message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let fileName = (file as NSString).lastPathComponent
        logger.log(level: level.osLogType, "[\(fileName):\(line)] \(function) - \(message)")
    }
}
