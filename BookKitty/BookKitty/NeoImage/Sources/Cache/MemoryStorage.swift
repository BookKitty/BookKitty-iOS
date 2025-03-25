import Foundation

public actor MemoryStorage {
    // MARK: - Properties

    var keys = Set<String>()

    /// 캐시는 NSCache로 접근합니다.
    private let storage = NSCache<NSString, StorageObject>()
    private let totalCostLimit: Int

    private var cleanTask: Task<Void, Never>?

    // MARK: - Lifecycle

    init(totalCostLimit: Int) {
        // 메모리가 사용할 수 있는 공간 상한선 (ImageCache 클래스에서 총 메모리공간의 1/4로 주입하고 있음) 데이터를 아래 private 속성에 주입시킵니다.
        self.totalCostLimit = totalCostLimit
        storage.totalCostLimit = totalCostLimit

        NeoLogger.shared.debug("initialized")

        Task {
            await setupCleanTask()
        }
    }

    // MARK: - Functions

    public func removeExpired() {
        for key in keys {
            let nsKey = key as NSString
            guard let object = storage.object(forKey: nsKey) else {
                keys.remove(key)
                continue
            }

            if object.isExpired {
                storage.removeObject(forKey: nsKey)
                keys.remove(key)
            }
        }
    }

    /// Removes all values in this storage.
    public func removeAll() {
        storage.removeAllObjects()
        keys.removeAll()
    }

    public func removeAllExceptPriority() async {
        let priorityKeys = keys.filter { $0.hasPrefix("priority_") }

        var priorityImagesData: [String: Data] = [:]

        for key in priorityKeys {
            if let data = value(forKey: key) {
                priorityImagesData[key] = data
            }
        }

        removeAll()

        for (key, data) in priorityImagesData {
            store(value: data, for: key, expiration: .days(7))

            let originalKey = key.replacingOccurrences(of: "priority_", with: "")
            store(value: data, for: originalKey, expiration: .days(7))
        }

        NeoLogger.shared.info("메모리 캐시 정리 완료: 우선순위 이미지 \(priorityImagesData.count)개 유지")
    }

    /// 캐시에 저장
    func store(
        value: Data,
        for hashedKey: String,
        expiration: StorageExpiration? = nil
    ) {
        let expiration = expiration ?? NeoImageConstants.expiration

        guard !expiration.isExpired else {
            return
        }

        let object = StorageObject(value as Data, expiration: expiration)

        storage.setObject(object, forKey: hashedKey as NSString)

        keys.insert(hashedKey)
    }

    /// 캐시에서 조회
    func value(
        forKey hashedKey: String,
        extendingExpiration: ExpirationExtending = .cacheTime
    ) -> Data? {
        guard let object = storage.object(forKey: hashedKey as NSString) else {
            return nil
        }

        if object.isExpired {
            return nil
        }

        object.extendExpiration(extendingExpiration)
        return object.value
    }

    private func setupCleanTask() {
        // Timer 대신 Task로 주기적인 정리 작업 수행
        cleanTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 120 * 1_000_000_000)

                // 취소 확인
                if Task.isCancelled {
                    break
                }

                // 만료된 항목 제거
                removeExpired()
            }
        }
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
