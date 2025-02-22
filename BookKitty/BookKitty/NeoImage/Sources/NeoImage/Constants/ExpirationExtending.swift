import Foundation

public enum StorageExpiration: Equatable, Sendable {
    /// 초 단위로 만료 시간 지정
    case seconds(TimeInterval)
    
    /// 일 단위로 만료 시간 지정
    case days(Int)
    
    /// 영구 저장 (만료되지 않음)
    case never
    
    var estimatedExpirationSinceNow: Date {
        let timeInterval: TimeInterval
        switch self {
        case .seconds(let seconds):
            timeInterval = seconds
        case .days(let days):
            timeInterval = TimeInterval(86400 * days)  // 86400 = 24 * 60 * 60
        case .never:
            return .distantFuture
        }
        return Date().addingTimeInterval(timeInterval)
    }
    
    var isExpired: Bool {
        return estimatedExpirationSinceNow.isPast
    }
}

public enum ExpirationExtending: Equatable, Sendable {
    /// 만료 시간을 연장하지 않음
    case none
    
    /// 현재 캐시 설정의 만료 시간만큼 연장
    case cacheTime
    
    /// 지정된 만료 시간으로 연장
    case expirationTime(StorageExpiration)
}
