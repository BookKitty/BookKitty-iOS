import Foundation

public actor MemoryStorageActor {
    // MARK: - Properties

    /// 캐시는 NSCache로 접근합니다.
    private let cache = NSCache<NSString, NSData>()
    private let totalCostLimit: Int

    // MARK: - Lifecycle

    init(totalCostLimit: Int) {
        // 메모리가 사용할 수 있는 공간 상한선 (ImageCache 클래스에서 총 메모리공간의 1/4로 주입하고 있음) 데이터를 아래 private 속성에 주입시킵니다.
        self.totalCostLimit = totalCostLimit
        cache.totalCostLimit = totalCostLimit
    }

    // MARK: - Functions

    /// 캐시에 저장
    func store(value: Data, forKey key: String, expiration _: StorageExpiration?) {
        cache.setObject(value as NSData, forKey: key as NSString)
    }

    /// 캐시에서 조회
    func value(forKey key: String) -> Data? {
        cache.object(forKey: key as NSString) as Data?
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
        cache.object(forKey: key as NSString) != nil
    }
}
