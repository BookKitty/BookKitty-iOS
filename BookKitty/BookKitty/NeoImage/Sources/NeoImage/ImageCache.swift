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
        
        /// 메모리 캐싱 관련 설정 과정입니다.
        /// NSProcessInfo를 통해 총 메모리 크기를 접근한 후, 메모리 상한선을 전체 메모리의 1/4로 한정합니다.
        let totalMemory = ProcessInfo.processInfo.physicalMemory
        let memoryLimit = totalMemory / 4
        self.memoryStorage = MemoryStorageActor(
            totalCostLimit: min(Int.max, Int(memoryLimit))
        )
        
        /// 디스크 캐시에 대한 설정을 여기서 정의해줍니다.
        let diskConfig = DiskStorage<Data>.Config(
            name: name,
            sizeLimit: 0,
            directory: FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        )
        
        /// 디스크 캐시 제어 관련 클래스 인스턴스 생성
        self.diskStorage = try DiskStorage(config: diskConfig)
    }
    
    /// 메모리와 디스크 캐시에 모두 데이터를 저장합니다.
    @ImageCacheActor
    public func store(
        _ data: Data,
        forKey key: String,
        expiration: StorageExpiration? = nil
    ) async throws {
        await memoryStorage.store(value: data, forKey: key, expiration: expiration)
        
        try await diskStorage.store(
            value: data,
            forKey: key,
            expiration: expiration
        )
    }
    /// 캐시로부터 저장된 이미지를 가져옵니다.
    /// 1차적으로 오버헤드가 적은 메모리를 먼저 확인합니다.
    /// 이후 메모리에 없을 경우, 디스크를 확인합니다.
    /// 디스크에 없을 경우 throw합니다.
    /// 디스크에 데이터를 확인할 경우, 다음 조회를 위해 해당 데이터를 메모리로 올립니다.
    public func retrieveImage(forKey key: String) async throws -> Data? {
        if let memoryData = await memoryStorage.value(forKey: key) {
            return memoryData
        }
        
        let diskData = try await diskStorage.value(forKey: key)
        
        if let diskData = diskData {
            await memoryStorage.store(
                value: diskData,
                forKey: key,
                expiration: .days(7)
            )
        }
        
        return diskData
    }
    
    /// 메모리와 디스크 모두에서 특정 키에 해당하는 이미지 데이터를 제거합니다.
    @ImageCacheActor
    public func removeImage(forKey key: String) async throws {
        // Remove from memory
        await memoryStorage.remove(forKey: key)
        
        // Remove from disk
        try await diskStorage.remove(forKey: key)
    }
    
    /// 메모리와 디스크 모두에 존재하는 모든 데이터를 제거합니다.
    @ImageCacheActor
    public func clearCache() async throws {
        await memoryStorage.removeAll()
        
        try await diskStorage.removeAll()
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

// MARK: - 메모리 영역 제어를 위한 actor입니다.

private actor MemoryStorageActor {
    /// 캐시는 NSCache로 접근합니다.
    private let cache = NSCache<NSString, NSData>()
    private let totalCostLimit: Int
    
    init(totalCostLimit: Int) {
        /// 메모리가 사용할 수 있는 공간 상한선 (ImageCache 클래스에서 총 메모리공간의 1/4로 주입하고 있음) 데이터를 아래 private 속성에 주입시킵니다.
        self.totalCostLimit = totalCostLimit
        self.cache.totalCostLimit = totalCostLimit
    }
    
    /// 캐시에 저장
    func store(value: Data, forKey key: String, expiration: StorageExpiration?) {
        cache.setObject(value as NSData, forKey: key as NSString)
    }
    
    /// 캐시에서 조회
    func value(forKey key: String) -> Data? {
        return cache.object(forKey: key as NSString) as Data?
    }
    
    /// 캐시에서 제거
    func remove(forKey key: String) {
        cache.removeObject(forKey: key as NSString)
    }
    
    /// 캐시에서 일괄 제거
    func removeAll() {
        cache.removeAllObjects()
    }
    
    /// 캐시에서 있는지 여부를 조회
    func isCached(forKey key: String) -> Bool {
        return cache.object(forKey: key as NSString) != nil
    }
}
