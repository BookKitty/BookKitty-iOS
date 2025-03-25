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

        let isPriority = hashedKey.hasPrefix("priority_")

        // 우선순위 여부로 같은 데이터가 디스크 캐시에 동시에 존재할 가능성이 있습니다.
        // 콜백이 불필요하며 글로벌 스레드에서 전적으로 실행되는 store에서 디스크 캐시에 대한 io작업을 최대한 수행토록하여 우선순위가 엇갈리는 동일한 데이터 유무를
        // 검토하고 제거하는 추가 로직을 구현했습니다.
        // 또한 일반 저장 시, 우선순위 적용 키가 캐싱되어있으면 중복 저장을 하지 않는 등의 엣지케이스도 고려했습니다.
        if isPriority {
            let originalKey = hashedKey.replacingOccurrences(of: "priority_", with: "")

            if await diskStorage.isCached(for: originalKey) {
                try await diskStorage.remove(for: originalKey)
                NeoLogger.shared.debug("원본 이미지 제거: \(originalKey)")
            }
        } else {
            if await diskStorage.isCached(for: "priority_" + hashedKey) {
                NeoLogger.shared.debug("우선순위 이미지가 존재하여 원본 저장 건너뜀: \(hashedKey)")
                return
            }
        }

        try await diskStorage.store(value: data, for: hashedKey)
    }

    public func retrieveImage(hashedKey: String) async throws -> Data? {
        let isPriority = hashedKey.hasPrefix("priority_")
        let otherKey: String
        if isPriority {
            otherKey = hashedKey.replacingOccurrences(of: "priority_", with: "")
        } else {
            otherKey = "priority_" + hashedKey
        }

        // 우선순위 키로 요청했는데, 일반 키로 저장되어있을때 -> 필요
        // 우선순위 키로 요청했는데, 우선순위 키로 저장되어있을때 -> 동기화 잘 되어있음
        // 일반 키로 요청했는데, 우선순위 키로 있을때 -> 다른 상황에서는 우선순위로 접근할 가능성 있음, 보류
        // 일반 키로 요청했는데, 일반 키로 있을때, -> 동기화 잘 되어있음

        if let memoryData = await memoryStorage.value(forKey: hashedKey) {
            return memoryData
        }

        if let memoryDataForOtherKey = await memoryStorage.value(forKey: otherKey) {
            if isPriority {
                changeDiskDirectoryToPriority(otherKey, memoryDataForOtherKey)
            }

            return memoryDataForOtherKey
        }

        if let diskData = try await diskStorage.value(for: hashedKey) {
            await memoryStorage.store(value: diskData, for: hashedKey)

            return diskData
        }

        if let diskDataForOtherKey = try await diskStorage.value(for: otherKey) {
            if isPriority {
                changeDiskDirectoryToPriority(otherKey, diskDataForOtherKey)
            }

            await memoryStorage.store(
                value: diskDataForOtherKey,
                for: hashedKey
            )

            return diskDataForOtherKey
        }

        return nil
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
    public func clearMemoryCache(keepPriorityImages: Bool = true) {
        Task {
            if keepPriorityImages {
                // 우선순위 이미지를 유지하는 전략
                await memoryStorage.removeAllExceptPriority()
            } else {
                // 모든 이미지 제거
                await memoryStorage.removeAll()
            }
        }
    }

    func changeDiskDirectoryToPriority(_ originKey: String, _ value: Data) {
        Task {
            guard !originKey.hasPrefix("priority_"),
                  await diskStorage.isCached(for: originKey)
            else {
                return
            } // 접두사가 없는 상태에서 disk에 원본 키가 없어야함.
            try await diskStorage.store(value: value, for: "priority_" + originKey)
            try await diskStorage.remove(for: originKey)

            NeoLogger.shared.debug("change diskStorage Directory Succeeded:\(Date())")
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
