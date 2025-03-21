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

        diskStorage = DiskStorage<Data>(fileManager: .default)

        NeoLogger.shared.debug("initialized")

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
            }
        }

        Task {
            await diskStorage.preloadPriorityToMemory()
        }
    }

    // MARK: - Functions

    /// 메모리와 디스크 캐시에 모두 데이터를 저장합니다.
    public func store(
        _ data: Data,
        for hashedKey: String
    ) async throws {
        await memoryStorage.store(value: data, for: hashedKey)

        try await diskStorage.store(value: data, for: hashedKey)
    }

    public func retrieveImage(hashedKey: String) async throws -> Data? {
        if let memoryData = await memoryStorage.value(forKey: hashedKey) {
            print("hashedKey from retrieveImage:", hashedKey)
            return memoryData
        }

        let diskData = try await diskStorage.value(for: hashedKey)

        if let diskData {
            await memoryStorage.store(value: diskData, for: hashedKey, expiration: .days(7))
        }

        return diskData
    }

    /// 메모리와 디스크 모두에 존재하는 모든 데이터를 제거합니다.
    public func clearCache() {
        Task {
            do {
                await memoryStorage.removeAll()

                try await diskStorage.removeAll()
            } catch {
                NeoLogger.shared.error("diskStorage clear failed")
            }
        }
    }

    @objc
    public func clearMemoryCache() {
        Task {
            await memoryStorage.removeAll()
        }
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
