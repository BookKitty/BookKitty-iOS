import Foundation

public enum NeoImageError: Error, Sendable {
    case requestError(reason: RequestErrorReason)

    case responseError(reason: ResponseErrorReason)

    case cacheError(reason: CacheErrorReason)

    // MARK: - Nested Types

    public enum RequestErrorReason: Sendable {
        case invalidURL
        case taskCancelled
        case invalidSessionTask
    }

    public enum ResponseErrorReason: Sendable {
        case networkError(description: String)
        case cancelled
        case invalidImageData
    }

    public enum CacheErrorReason: Sendable {
        case invalidData

        case storageNotReady
        case fileNotFound(key: String)

        case cannotCreateDirectory(error: Error)
        case cannotSetCacheFileAttribute(path: String, attribute: [FileAttributeKey: Sendable])
    }
}

extension NeoImageError.RequestErrorReason {
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "잘못된 URL"
        case .taskCancelled:
            return "작업이 취소됨"
        case .invalidSessionTask:
            return "SessionDataTask가 존재하지 않음"
        }
    }
}

extension NeoImageError.ResponseErrorReason {
    var localizedDescription: String {
        switch self {
        case let .networkError(description):
            return "네트워크 에러: \(description)"
        case .cancelled:
            return "다운로드가 취소됨"
        case .invalidImageData:
            return "유효하지 않은 이미지 데이터"
        }
    }
}

extension NeoImageError.CacheErrorReason {
    var localizedDescription: String {
        switch self {
        case .invalidData:
            return "유효하지 않은 데이터"
        case .storageNotReady:
            return "저장소가 준비되지 않음"
        case let .fileNotFound(key):
            return "파일을 찾을 수 없음: \(key)"
        case let .cannotCreateDirectory(error):
            return "디렉토리 생성 실패: \(error.localizedDescription)"
        case let .cannotSetCacheFileAttribute(path, attributes):
            return "캐시 파일 속성 변경 실패 - 경로:\(path), 속성:\(attributes.keys)"
        }
    }
}
