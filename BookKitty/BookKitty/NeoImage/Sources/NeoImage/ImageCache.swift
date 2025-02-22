import Foundation

public final class ImageCache {
    
    /// ERROR: Static property 'shared' is not concurrency-safe because non-'Sendable' type 'ImageCache' may have shared mutable state
    ///
    /// ```
    /// public static let shared = ImageCache()
    /// ```
    /// Swift 6에서는 동시성 안정성 검사가 더욱 엄격해졌습니다. 이로 인해 여러 스레드에서 동시에 접근할 수 있는 공유 상태 (shared mutable state)인 싱글톤 패턴을 사용할 경우,위 에러가 발생합니다.
    /// 이는 별도의 가변 프로퍼티를 클래스 내부에 지니고 있지 않음에도 발생하는 에러입니다
    public static let shared = ImageCache()
    
    // MARK: - Properties
    private let memoryStorage: MemoryStorage
    private let diskStorage: DiskStorage<Data>
    
    // MARK: - Initialization
    public init(name: String) throws {
        guard !name.isEmpty else {
            throw CacheError.invalidCacheKey
        }
        
        // Memory cache configuration
        let totalMemory = ProcessInfo.processInfo.physicalMemory
        let memoryLimit = totalMemory / 4
        let memoryCacheConfig = MemoryStorage.Config(
            totalCostLimit: (memoryLimit > Int.max) ? Int.max : Int(memoryLimit)
        )
        self.memoryStorage = MemoryStorage(config: memoryCacheConfig)
        
        // Disk cache configuration
        let diskConfig = DiskStorage.Config(
            name: name,
            sizeLimit: 0,
            directory: FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        )
        self.diskStorage = try DiskStorage(config: diskConfig)
    }
    
    // MARK: - Public Methods
    
    /// Stores an image to both memory and disk cache
    public func store(
        _ data: Data,
        forKey key: String,
        expiration: StorageExpiration? = nil
    ) async throws {
        // Store in memory
        memoryStorage.store(value: data, forKey: key, expiration: expiration)
        
        // Store in disk
        try await diskStorage.store(
            value: data,
            forKey: key,
            expiration: expiration
        )
    }
    
    /// Retrieves an image from cache (first checks memory, then disk)
    public func retrieveImage(forKey key: String) async throws -> Data? {
        // Check memory cache first
        if let memoryData = memoryStorage.value(forKey: key) {
            return memoryData
        }
        
        // If not in memory, check disk
        let diskData = try await diskStorage.value(forKey: key)
        
        // If found in disk, store in memory for next time
        if let diskData = diskData {
            memoryStorage.store(
                value: diskData,
                forKey: key,
                expiration: .days(7)
            )
        }
        
        return diskData
    }
    
    /// Removes an image from both memory and disk cache
    public func removeImage(forKey key: String) async throws {
        // Remove from memory
        memoryStorage.remove(forKey: key)
        
        // Remove from disk
        try await diskStorage.remove(forKey: key)
    }
    
    /// Clears all cached images from both memory and disk
    public func clearCache() async throws {
        // Clear memory
        memoryStorage.removeAll()
        
        // Clear disk
        try await diskStorage.removeAll()
    }
    
    /// Checks if an image exists in cache (either memory or disk)
    public func isCached(forKey key: String) async -> Bool {
        if memoryStorage.isCached(forKey: key) {
            return true
        }
        return await diskStorage.isCached(forKey: key)
    }
}

// MARK: - Memory Storage
private final class MemoryStorage {
    private let cache = NSCache<NSString, NSData>()
    private let lock = NSLock()
    
    struct Config {
        let totalCostLimit: Int
    }
    
    init(config: Config) {
        cache.totalCostLimit = config.totalCostLimit
    }
    
    func store(value: Data, forKey key: String, expiration: StorageExpiration?) {
        lock.lock()
        defer { lock.unlock() }
        cache.setObject(value as NSData, forKey: key as NSString)
    }
    
    func value(forKey key: String) -> Data? {
        lock.lock()
        defer { lock.unlock() }
        return cache.object(forKey: key as NSString) as Data?
    }
    
    func remove(forKey key: String) {
        lock.lock()
        defer { lock.unlock() }
        cache.removeObject(forKey: key as NSString)
    }
    
    func removeAll() {
        lock.lock()
        defer { lock.unlock() }
        cache.removeAllObjects()
    }
    
    func isCached(forKey key: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return cache.object(forKey: key as NSString) != nil
    }
}
