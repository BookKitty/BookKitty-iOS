import OSLog

public enum LogSubSystem: String, CaseIterable, Sendable {
    case bookOCR = "bookOCR"
    case bookRecommendation = "bookRecommendation"
    case designSystem = "designSystem"
    case database = "database"
    case app = "app"
}

public enum LogCategory: String, CaseIterable, Sendable {
    case general = "general"
    case network = "network"
    case userAction = "userAction"
    case lifecycle = "lifecycle"
}

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
