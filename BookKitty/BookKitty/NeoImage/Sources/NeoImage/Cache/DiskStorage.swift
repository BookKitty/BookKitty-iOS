import Foundation

class DiskStorage<T: DataTransformable>: @unchecked Sendable {
    // MARK: - Properties

    private let config: Config

    private let directoryURL: URL

    private let serialActor = Actor()
    private var storageReady = true

    // MARK: - Lifecycle

    /// FileManager를 통해 디렉토리를 생성하는 과정에서 에러가 발생할 수 있기 때문에 인스턴스 생성 자체에서 throws 키워드를 기입해줍니다.
    init(config: Config) throws {
        // 외부에서 주입된 디스크 저장소에 대한 설정값과 Creation 구조체로 생성된 디렉토리 URL와 cacheName을 생성 및 self.directoryURL에
        // 저장합니다.
        self.config = config
        let creation = Creation(config)
        directoryURL = creation.directoryURL
        try prepareDirectory()
    }

    // MARK: - Functions

    func store(value: T, forKey key: String, expiration: StorageExpiration? = nil) async throws {
        guard let data = try? value.toData() else {
            throw CacheError.invalidData
        }
        // Disk에 대한 접근이 패키지 외부에서 동시에 이루어질 경우, 동일한 위치에 다른 데이터가 덮어씌워지는 data race 상황이 됩니다. 이를 방지하고자, 기존
        // Kingfisher에서는 DispatchQueue를 통해  직렬화 큐를 구현한 후, store(Write), value(Read)를 직렬화 큐에 전송하여
        // 순차적인 실행이 보장되게 하였습니다.
        // 이를 Swift Concurrency로 변경하고자, 동일한 직렬화 기능을 수행하는 Actor 클래스로 대체하였습니다.
        try await serialActor.run {
            // 별도로 메서드를 통해 기한을 전달하지 않으면, 기본값으로 config.expiration인 7일로 정의합니다.
            let expiration = expiration ?? self.config.expiration
            let fileURL = self.cacheFileURL(forKey: key)
            // Foundation 내부 Data 타입의 내장 메서드입니다.
            // 해당 위치로 data 내부 컨텐츠를 write 합니다.
            try data.write(to: fileURL)

            // FileManager를 통해 파일 작성 시 전달해줄 파일의 속성입니다.
            // 생성된 날짜, 수정된 일자를 실제 수정된 시간이 아닌, 만료 예정 시간을 저장하는 용도로 재활용합니다.
            // 실제로, 파일 시스템의 기본속성을 활용하기에 추가적인 저장공간이 필요 없음
            // 파일과 만료 정보가 항상 동기화되어 있음 (파일이 삭제되면 만료 정보도 자동으로 삭제)
            let attributes: [FileAttributeKey: Any] = [
                .creationDate: Date(),
                .modificationDate: expiration.estimatedExpirationSinceNow,
            ]

            // 파일의 메타데이터가 업데이트됨
            // 이는 디스크에 대한 I/O 작업을 수반
            // 파일의 내용은 변경되지 않고 속성만 변경
            try FileManager.default.setAttributes(attributes, ofItemAtPath: fileURL.path)
        }
    }

    func value(
        forKey key: String, // 캐시의 키
        extendingExpiration: ExpirationExtending = .cacheTime // 현재 Confiㅎ
    ) async throws -> T? {
        try await serialActor.run { () -> T? in
            // 주어진 키에 대한 캐시 파일 URL을 생성
            let fileURL = cacheFileURL(forKey: key)
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                return nil
            }

            // 파일에서 데이터를 읽어옴
            let data = try Data(contentsOf: fileURL)
            // DataTransformable 프로토콜의 fromData를 사용해 원본 타입으로 변환
            let obj = try T.fromData(data)

            // 해당 파일이 조회되었기 때문에, 만료 시간 연장을 처리합니다.
            // "캐시 적중(Cache Hit)"이 발생했을 때 해당 데이터의 생명주기를 연장하는 일반적인 캐시 전략입니다.
            // LRU(Least Recently Used)
            if extendingExpiration != .none {
                let expirationDate: Date
                switch extendingExpiration {
                case .none:
                    return obj
                case .cacheTime:
                    expirationDate = config.expiration.estimatedExpirationSinceNow
                // .expirationTime: 지정된 새로운 만료 시간으로 연장
                case let .expirationTime(storageExpiration):
                    expirationDate = storageExpiration.estimatedExpirationSinceNow
                }

                let attributes: [FileAttributeKey: Any] = [
                    .creationDate: Date(),
                    .modificationDate: expirationDate,
                ]

                try FileManager.default.setAttributes(attributes, ofItemAtPath: fileURL.path)
            }

            return obj
        }
    }

    /// 특정 키에 해당하는 파일을 삭제하는 메서드
    func remove(forKey key: String) async throws {
        try await serialActor.run {
            let fileURL = cacheFileURL(forKey: key)
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
            }
        }
    }

    /// 디렉토리 내의 모든 파일을 삭제하는 메서드
    func removeAll() async throws {
        try await serialActor.run {
            let fileManager = FileManager.default
            let contents = try fileManager.contentsOfDirectory(
                at: directoryURL,
                includingPropertiesForKeys: nil,
                options: []
            )
            for fileURL in contents {
                try fileManager.removeItem(at: fileURL)
            }
        }
    }

    /// 캐시 확인
    func isCached(forKey key: String) async -> Bool {
        let fileURL = cacheFileURL(forKey: key)
        return await serialActor.run {
            FileManager.default.fileExists(atPath: fileURL.path)
        }
    }
}

extension DiskStorage {
    private func cacheFileURL(forKey key: String, forcedExtension: String? = nil) -> URL {
        let fileName = cacheFileName(forKey: key, forcedExtension: forcedExtension)

        return directoryURL.appendingPathComponent(fileName, isDirectory: false)
    }

    /// 사전에 패키지에서 설정된 Config 구조체를 통해 파일명을 해시화하기로 설정했는지 여부, 임의로 전달된 접미사 단어 유무에 따라 캐시될때 저장될 파일명을 변환하여
    /// 반환해줍니다.
    private func cacheFileName(forKey key: String, forcedExtension: String? = nil) -> String {
        if config.usesHashedFileName {
            let hashedKey = key.sha256
            if let ext = forcedExtension ?? config.pathExtension {
                return "\(hashedKey).\(ext)"
            }
            return hashedKey
        } else {
            if let ext = forcedExtension ?? config.pathExtension {
                return "\(key).\(ext)"
            }
            // 해시화 설정을 false로 하고, pathExtension에 별도 조작을 하지 않을 경우,
            // key를 그대로 반환하는 경우도 있습니다.
            return key
        }
    }

    private func prepareDirectory() throws {
        // config에 custom fileManager를 주입할 수 있기 때문에, 여기서 .default를 접근하지 않고 Config 내부 fileManager를
        // 접근합니다.
        let fileManager = config.fileManager
        let path = directoryURL.path

        // Creation 구조체를 통해 생성된 url이 FileSystem에 존재하는지 검증
        guard !fileManager.fileExists(atPath: path) else {
            return
        }

        do {
            // FileManager를 통해 해당 path에 디렉토리 생성
            try fileManager.createDirectory(
                atPath: path,
                withIntermediateDirectories: true,
                attributes: nil
            )
        } catch {
            // 만일 디렉토리 생성이 실패할경우, storageReady를 false로 변경합니다.
            // 이는 추후 flag로 동작합니다.
            storageReady = false
            throw CacheError.cannotCreateDirectory(error)
        }
    }
}

/// 직렬화를 위한 간단한 액터
/// 에러 처리 여부에 따라 오버로드되어있기에, 에러처리가 필요한지 여부에 따라 선택적으로 try 키워드를 삽입
actor Actor {
    func run<T>(_ operation: @Sendable () throws -> T) throws -> T {
        try operation()
    }

    func run<T>(_ operation: @Sendable () -> T) -> T {
        operation()
    }
}

extension DiskStorage {
    /// Represents the configuration used in a ``DiskStorage/Backend``.
    public struct Config: @unchecked Sendable {
        // MARK: - Properties

        /// The file size limit on disk of the storage in bytes.
        /// `0` means no limit.
        public var sizeLimit: UInt

        /// The `StorageExpiration` used in this disk storage.
        /// The default is `.days(7)`, which means that the disk cache will expire in one week if
        /// not accessed anymore.
        public var expiration = StorageExpiration.days(7)

        /// The preferred extension of the cache item. It will be appended to the file name as its
        /// extension.
        /// The default is `nil`, which means that the cache file does not contain a file extension.
        public var pathExtension: String?

        /// Whether the cache file name will be hashed before storing.
        ///
        /// The default is `true`, which means that file name is hashed to protect user information
        /// (for example, the
        /// original download URL which is used as the cache key).
        public var usesHashedFileName = true

        /// Whether the image extension will be extracted from the original file name and appended
        /// to the hashed file
        /// name, which will be used as the cache key on disk.
        ///
        /// The default is `false`.
        public var autoExtAfterHashedFileName = false

        /// A closure that takes in the initial directory path and generates the final disk cache
        /// path.
        ///
        /// You can use it to fully customize your cache path.
        public var cachePathBlock: (@Sendable (_ directory: URL, _ cacheName: String) -> URL)! = {
            directory, cacheName in
            directory.appendingPathComponent(cacheName, isDirectory: true)
        }

        /// The desired name of the disk cache.
        ///
        /// This name will be used as a part of the cache folder name by default.
        public let name: String

        let fileManager: FileManager
        let directory: URL?

        // MARK: - Lifecycle

        /// Creates a config value based on the given parameters.
        ///
        /// - Parameters:
        ///   - name: The name of the cache. It is used as part of the storage folder and to
        /// identify the disk storage.
        ///   Two storages with the same `name` would share the same folder on the disk, and this
        /// should be prevented.
        ///   - sizeLimit: The size limit in bytes for all existing files in the disk storage.
        ///   - fileManager: The `FileManager` used to manipulate files on the disk. The default is
        /// `FileManager.default`.
        ///   - directory: The URL where the disk storage should reside. The storage will use this
        /// as the root folder,
        ///   and append a path that is constructed by the input `name`. The default is `nil`,
        /// indicating that
        ///   the cache directory under the user domain mask will be used.
        public init(
            name: String,
            sizeLimit: UInt,
            fileManager: FileManager = .default,
            directory: URL? = nil
        ) {
            self.name = name
            self.fileManager = fileManager
            self.directory = directory
            self.sizeLimit = sizeLimit
        }
    }
}

extension DiskStorage {
    struct Creation {
        // MARK: - Properties

        let directoryURL: URL
        let cacheName: String

        // MARK: - Lifecycle

        init(_ config: Config) {
            let url: URL
            if let directory = config.directory {
                url = directory
            } else {
                url = config.fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            }

            cacheName = "com.neoself.NeoImage.ImageCache.\(config.name)"
            directoryURL = config.cachePathBlock(url, cacheName)
        }
    }
}
