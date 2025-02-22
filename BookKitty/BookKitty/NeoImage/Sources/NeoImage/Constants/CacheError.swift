enum CacheError: Error {
    // 데이터 관련 에러
    case invalidData
    case invalidImage
    case dataToImageConversionFailed
    case imageToDataConversionFailed
    
    // 저장소 관련 에러
    case diskStorageError(Error)
    case memoryStorageError(Error)
    case storageNotReady
    
    // 파일 관련 에러
    case fileNotFound(String)  // key
    case cannotCreateDirectory(Error)
    case cannotWriteToFile(Error)
    case cannotReadFromFile(Error)
    
    // 캐시 키 관련 에러
    case invalidCacheKey
    
    // 기타
    case unknown(Error)
    
    var localizedDescription: String {
        switch self {
        case .invalidData:
            return "The data is invalid or corrupted"
        case .invalidImage:
            return "The image data is invalid"
        case .dataToImageConversionFailed:
            return "Failed to convert data to image"
        case .imageToDataConversionFailed:
            return "Failed to convert image to data"
            
        case .diskStorageError(let error):
            return "Disk storage error: \(error.localizedDescription)"
        case .memoryStorageError(let error):
            return "Memory storage error: \(error.localizedDescription)"
        case .storageNotReady:
            return "The storage is not ready"
            
        case .fileNotFound(let key):
            return "File not found for key: \(key)"
        case .cannotCreateDirectory(let error):
            return "Cannot create directory: \(error.localizedDescription)"
        case .cannotWriteToFile(let error):
            return "Cannot write to file: \(error.localizedDescription)"
        case .cannotReadFromFile(let error):
            return "Cannot read from file: \(error.localizedDescription)"
            
        case .invalidCacheKey:
            return "The cache key is invalid"
            
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
}
