import Foundation
import UIKit

/// 쓰기 제어와 같은 동시성이 필요한 부분만 선택적으로 제어하기 위해 전체 ImageCache를 actor로 변경하지 않고, ImageCacheActor 생성
/// actor를 사용하면 모든 동작이 actor의 실행큐를 통과해야하기 때문에, 동시성 보호가 불필요한 read-only 동작도 직렬화되며 오버헤드가 발생
public final class ImageCache: Sendable {
    // MARK: - Static Properties

    public static let shared = ImageCache(name: "default")

    // MARK: - Properties

    public let memoryStorage: MemoryStorage
    public let diskStorage: DiskStorage<Data>

    // MARK: - Lifecycle

    public init(
        name: String
    ) {
        if name.isEmpty {
            fatalError(
                "You should specify a name for the cache. A cache with empty name is not permitted."
            )
        }

        let totalMemory = ProcessInfo.processInfo.physicalMemory
        let memoryLimit = totalMemory / 4

        memoryStorage = MemoryStorage(
            totalCostLimit: min(Int.max, Int(memoryLimit))
        )

        diskStorage = DiskStorage<Data>(
            name: name,
            fileManager: .default
        )

        Task { @MainActor in
            let notifications: [(Notification.Name, Selector)]
            notifications = [
                (UIApplication.didReceiveMemoryWarningNotification, #selector(clearMemoryCache)),
                (UIApplication.willTerminateNotification, #selector(cleanExpiredDiskCache)),
            ]

            for notification in notifications {
                NotificationCenter.default.addObserver(
                    self,
                    selector: notification.1,
                    name: notification.0,
                    object: nil
                )
            } // 각 알림에 대해 옵저버 등록
        }
    }

    // MARK: - Functions

    /// 메모리와 디스크 캐시에 모두 데이터를 저장합니다.
    public func store(
        _ data: Data,
        forKey key: String,
        expiration: StorageExpiration? = nil
    ) async throws {
        memoryStorage.store(value: data, forKey: key, expiration: expiration)

        try await diskStorage.store(
            value: data,
            forKey: key,
            expiration: expiration
        )
    }

    public func retrieveImage(forKey key: String) async throws -> Data? {
        if let memoryData = memoryStorage.value(forKey: key) {
            return memoryData
        }

        let diskData = try await diskStorage.value(forKey: key)

        if let diskData {
            memoryStorage.store(
                value: diskData,
                forKey: key,
                expiration: .days(7)
            )
        }

        return diskData
    }

    /// 메모리와 디스크 모두에 존재하는 모든 데이터를 제거합니다.
    public func clearCache() async throws {
        memoryStorage.removeAll()

        try await diskStorage.removeAll()
    }

    @objc
    public func clearMemoryCache() {
        memoryStorage.removeAll()
    }

    @objc
    func cleanExpiredDiskCache() {
        Task {
            do {
                var removed: [URL] = []
                let removedExpired = try await self.diskStorage.removeExpiredValues()
                removed.append(contentsOf: removedExpired)
            } catch {}
        }
    }
}
