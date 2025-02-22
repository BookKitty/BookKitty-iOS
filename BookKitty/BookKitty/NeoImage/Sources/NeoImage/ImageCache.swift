import Foundation

/// 쓰기 제어와 같은 동시성이 필요한 부분만 선택적으로 제어하기 위해 전체 ImageCache를 actor로 변경하지 않고, ImageCacheActor 생성
/// actor를 사용하면 모든 동작이 actor의 실행큐를 통과해야하기 때문에, 동시성 보호가 불필요한 read-only 동작도 직렬화되며 오버헤드가 발생
@globalActor public actor ImageCacheActor {
    public static let shared = ImageCacheActor()
}

public final class ImageCache {
    
    /// ERROR: Static property 'shared' is not concurrency-safe because non-'Sendable' type 'ImageCache' may have shared mutable state
    /// ```
    /// public static let shared = ImageCache()
    /// ```
    /// Swift 6에서는 동시성 안정성 검사가 더욱 엄격해졌습니다. 이로 인해 여러 스레드에서 동시에 접근할 수 있는 공유 상태 (shared mutable state)인 싱글톤 패턴을 사용할 경우,위 에러가 발생합니다.
    /// 이는 별도의 가변 프로퍼티를 클래스 내부에 지니고 있지 않음에도 발생하는 에러입니다
    /// 이를 해결하기 위해선, Actor를 사용하거나, Serial Queue를 사용해 동기화를 해줘야 합니다.
    @ImageCacheActor
    public static let shared = try! ImageCache(name: "default")
    
    // MARK: - Properties
    private let memoryStorage: MemoryStorageActor
    private let diskStorage: DiskStorage<Data>
    
    // MARK: - Initialization
    public init(name: String) throws {
        guard !name.isEmpty else {
            throw CacheError.invalidCacheKey
        }
        
        // Memory cache configuration
        let totalMemory = ProcessInfo.processInfo.physicalMemory
        let memoryLimit = totalMemory / 4
        self.memoryStorage = MemoryStorageActor(
                    totalCostLimit: (memoryLimit > Int.max) ? Int.max : Int(memoryLimit)
                )
        // Disk cache configuration
        let diskConfig = DiskStorage<Data>.Config(
            name: name,
            sizeLimit: 0,
            directory: FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        )
        self.diskStorage = try DiskStorage(config: diskConfig)
    }
    
    // MARK: - Public Methods
    /// Stores an image to both memory and disk cache
    @ImageCacheActor
    public func store(
        _ data: Data,
        forKey key: String,
        expiration: StorageExpiration? = nil
    ) async throws {
        // Store in memory
        await memoryStorage.store(value: data, forKey: key, expiration: expiration)
        
        // Store in disk
        try await diskStorage.store(
            value: data,
            forKey: key,
            expiration: expiration
        )
    }
    
    /// Retrieves an image from cache (first checks memory, then disk)
    @ImageCacheActor
    public func retrieveImage(forKey key: String) async throws -> Data? {
        // Check memory cache first
        if let memoryData = await memoryStorage.value(forKey: key) {
            return memoryData
        }
        
        // If not in memory, check disk
        let diskData = try await diskStorage.value(forKey: key)
        
        // If found in disk, store in memory for next time
        if let diskData = diskData {
            await memoryStorage.store(
                value: diskData,
                forKey: key,
                expiration: .days(7)
            )
        }
        
        return diskData
    }
    
    /// Removes an image from both memory and disk cache
    @ImageCacheActor
    public func removeImage(forKey key: String) async throws {
        // Remove from memory
        await memoryStorage.remove(forKey: key)
        
        // Remove from disk
//        try await diskStorage.remove(forKey: key)
    }
    
    /// Clears all cached images from both memory and disk
    @ImageCacheActor
    public func clearCache() async throws {
        // Clear memory
        await memoryStorage.removeAll()
        
        // Clear disk
//        try await diskStorage.removeAll()
    }
    
    /// Checks if an image exists in cache (either memory or disk)
    @ImageCacheActor
    public func isCached(forKey key: String) async -> Bool {
        if await memoryStorage.isCached(forKey: key) {
            return true
        }
        return await diskStorage.isCached(forKey: key)
    }
}

// MARK: - Memory Storage
private actor MemoryStorageActor {
    private let cache = NSCache<NSString, NSData>()
    private let totalCostLimit: Int
    
    init(totalCostLimit: Int) {
        self.totalCostLimit = totalCostLimit
        self.cache.totalCostLimit = totalCostLimit
    }
    
    func store(value: Data, forKey key: String, expiration: StorageExpiration?) {
        cache.setObject(value as NSData, forKey: key as NSString)
    }
    
    func value(forKey key: String) -> Data? {
        return cache.object(forKey: key as NSString) as Data?
    }
    
    func remove(forKey key: String) {
        cache.removeObject(forKey: key as NSString)
    }
    
    func removeAll() {
        cache.removeAllObjects()
    }
    
    func isCached(forKey key: String) -> Bool {
        return cache.object(forKey: key as NSString) != nil
    }
}
