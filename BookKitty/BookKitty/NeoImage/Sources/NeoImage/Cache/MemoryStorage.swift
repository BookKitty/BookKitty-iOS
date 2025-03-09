import Foundation

public class MemoryStorage: @unchecked Sendable {
    // MARK: - Properties

    var keys = Set<String>()

    /// 캐시는 NSCache로 접근합니다.
    private let storage = NSCache<NSString, StorageObject>()
    private let totalCostLimit: Int

    private var cleanTimer: Timer?
    private let lock = NSLock()

    // MARK: - Lifecycle

    init(totalCostLimit: Int) {
        // 메모리가 사용할 수 있는 공간 상한선 (ImageCache 클래스에서 총 메모리공간의 1/4로 주입하고 있음) 데이터를 아래 private 속성에 주입시킵니다.
        self.totalCostLimit = totalCostLimit
        storage.totalCostLimit = totalCostLimit

        cleanTimer = .scheduledTimer(withTimeInterval: 120, repeats: true) { [weak self] _ in
            guard let self else {
                return
            }
            removeExpired()
        }
    }

    // MARK: - Functions

    public func removeExpired() {
        lock.lock()
        defer { lock.unlock() }
        for key in keys {
            let nsKey = key as NSString
            guard let object = storage.object(forKey: nsKey) else {
                // This could happen if the object is moved by cache `totalCostLimit` or
                // `countLimit` rule.
                // We didn't remove the key yet until now, since we do not want to introduce
                // additional lock.
                // See https://github.com/onevcat/Kingfisher/issues/1233
                keys.remove(key)
                continue
            }

            if object.isExpired {
                storage.removeObject(forKey: nsKey)
                keys.remove(key)
            }
        }
    }

    /// 캐시에서 있는지 여부를 조회
    public func isCached(forKey key: String) -> Bool {
        guard let _ = value(forKey: key, extendingExpiration: .none) else {
            return false
        }
        return true
    }

    /// 캐시에서 제거
    public func remove(forKey key: String) {
        lock.lock()
        defer { lock.unlock() }
        storage.removeObject(forKey: key as NSString)
        keys.remove(key)
    }

    /// Removes all values in this storage.
    public func removeAll() {
        lock.lock()
        defer { lock.unlock() }
        storage.removeAllObjects()
        keys.removeAll()
    }

    /// 캐시에 저장
    func store(
        value: Data,
        forKey key: String,
        expiration: StorageExpiration? = nil
    ) {
        lock.lock()
        defer { lock.unlock() }
        let expiration = expiration ?? NeoImageConstants.expiration
        // The expiration indicates that already expired, no need to store.
        guard !expiration.isExpired else {
            return
        }

        let object = StorageObject(value as Data, expiration: expiration)

        storage.setObject(object, forKey: key as NSString)
        keys.insert(key)
    }

    /// 캐시에서 조회
    func value(forKey key: String, extendingExpiration: ExpirationExtending = .cacheTime) -> Data? {
        guard let object = storage.object(forKey: key as NSString) else {
            return nil
        }
        if object.isExpired {
            return nil
        }
        object.extendExpiration(extendingExpiration)
        return object.value
    }
}

extension MemoryStorage {
    class StorageObject {
        // MARK: - Properties

        var value: Data
        let expiration: StorageExpiration

        private(set) var estimatedExpiration: Date

        // MARK: - Computed Properties

        var isExpired: Bool {
            estimatedExpiration.isPast
        }

        // MARK: - Lifecycle

        init(_ value: Data, expiration: StorageExpiration) {
            self.value = value
            self.expiration = expiration

            estimatedExpiration = expiration.estimatedExpirationSinceNow
        }

        // MARK: - Functions

        func extendExpiration(_ extendingExpiration: ExpirationExtending = .cacheTime) {
            switch extendingExpiration {
            case .none:
                return
            case .cacheTime:
                estimatedExpiration = expiration.estimatedExpirationSinceNow
            case let .expirationTime(expirationTime):
                estimatedExpiration = expirationTime.estimatedExpirationSinceNow
            }
        }
    }
}
