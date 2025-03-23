import SwiftUI
import UIKit

/// NeoImage 바인딩을 위한 ObservableObject
@MainActor
class NeoImageBinder: ObservableObject {
    // MARK: - Properties

    /// 다운로드 작업 정보
    var downloadTask: DownloadTask?
    // 이미지 로딩 상태와 결과
    @Published var loaded = false
    @Published var animating = false
    @Published var loadedImage: UIImage? = nil
    @Published var progress = Progress()

    private var loading = false

    // MARK: - Computed Properties

    /// 로딩 상태 정보
    var loadingOrSucceeded: Bool {
        loading || loadedImage != nil
    }

    // MARK: - Lifecycle

    init() {}

    // MARK: - Functions

    func markLoading() {
        loading = true
    }

    func markLoaded() {
        loaded = true
    }

    func start(url: URL?, options _: NeoImageOptions?) async {
        guard let url else {
            loading = false
            markLoaded()
            return
        }

        loading = true
        progress = .init()

        let hashedKey = url.absoluteString.sha256
        if let cachedData = try? await ImageCache.shared.retrieveImage(hashedKey: hashedKey),
           let cachedImage = UIImage(data: cachedData) {
            loadedImage = cachedImage
            loading = false
            markLoaded()
            return
        }

        if let task = downloadTask {
            await task.cancel()
            downloadTask = nil
        }

        do {
            let task = try await ImageDownloader.default.createTask(with: url)
            downloadTask = task
            let hashedKey = url.absoluteString.sha256

            let result = try await ImageDownloader.default.downloadImage(
                with: task,
                for: url,
                hashedKey: hashedKey
            )

            loadedImage = result.image
            loading = false
            markLoaded()
        } catch {
            loadedImage = nil
            loading = false
            markLoaded()
        }
    }

    func cancel() async {
        await downloadTask?.cancel()
        downloadTask = nil
        loading = false
    }
}

/// SwiftUI에서 사용 가능한 비동기 이미지 로딩 View
public struct NeoImage: View {
    // MARK: - Nested Types

    /// 이미지 소스를 나타내는 열거형
    public enum Source {
        case url(URL?)
        case urlString(String?)
    }

    // MARK: - SwiftUI Properties

    /// 이미지 로딩 바인더
    @StateObject private var binder = NeoImageBinder()

    // MARK: - Properties

    /// 이미지 소스
    private let source: Source

    // 옵션 및 콜백
    private var placeholder: AnyView?
    private var options: NeoImageOptions
    private var onSuccess: ((ImageLoadingResult) -> Void)?
    private var onFailure: ((Error) -> Void)?
    private var contentMode: SwiftUI.ContentMode

    // MARK: - Lifecycle

    // MARK: - Initializers

    /// URL로 초기화
    public init(url: URL?) {
        source = .url(url)
        options = .default
        contentMode = .fill
    }

    /// URL 문자열로 초기화
    public init(urlString: String?) {
        source = .urlString(urlString)
        options = .default
        contentMode = .fill
    }

    // MARK: - Content Properties

    // MARK: - View 구현

    public var body: some View {
        ZStack {
            // 이미지가 로드된 경우 표시
            if let image = binder.loadedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode == .fill ? .fill : .fit)
            }
            // 로딩 중이거나 로드되지 않은 경우 플레이스홀더 표시
            else if !binder.loaded || binder.loadedImage == nil {
                if let placeholder {
                    placeholder
                }
            }
        }
        .clipped() // 이미지가 경계를 넘지 않도록 클리핑
        .onAppear {
            // 뷰가 나타날 때 이미지 로딩 시작
            startLoading()
        }
        .onDisappear {
            // 옵션에 따라 뷰가 사라질 때 로딩 취소
            if options.cancelOnDisappear {
                Task { await binder.cancel() }
            }
        }
    }

    // MARK: - Functions

    // MARK: - 모디파이어

    /// 플레이스홀더 이미지 설정
    public func placeholder(_ content: @escaping () -> some View) -> NeoImage {
        var result = self
        result.placeholder = AnyView(content())
        return result
    }

    /// 옵션 설정
    public func options(_ options: NeoImageOptions) -> NeoImage {
        var result = self
        result.options = options
        return result
    }

    /// 이미지 로딩 성공 시 호출될 콜백
    public func onSuccess(_ action: @escaping (ImageLoadingResult) -> Void) -> NeoImage {
        var result = self
        result.onSuccess = action
        return result
    }

    /// 이미지 로딩 실패 시 호출될 콜백
    public func onFailure(_ action: @escaping (Error) -> Void) -> NeoImage {
        var result = self
        result.onFailure = action
        return result
    }

    /// 페이드 트랜지션 설정
    public func fade(duration: TimeInterval = 0.3) -> NeoImage {
        var result = self
        result.options = NeoImageOptions(
            transition: .fade(duration),
            cacheExpiration: result.options.cacheExpiration
        )
        return result
    }

    /// 콘텐츠 모드 설정 (fill/fit)
    public func contentMode(_ contentMode: SwiftUI.ContentMode) -> NeoImage {
        var result = self
        result.contentMode = contentMode
        return result
    }

    /// 뷰가 사라질 때 다운로드 취소 여부 설정
    public func cancelOnDisappear(_ cancel: Bool) -> NeoImage {
        var result = self
        var newOptions = result.options
        newOptions.cancelOnDisappear = cancel
        result.options = newOptions
        return result
    }

    private func startLoading() {
        // 이미 로딩 중이거나 성공한 경우 스킵
        if binder.loadingOrSucceeded {
            return
        }

        let url: URL? = {
            switch source {
            case let .url(url):
                return url
            case let .urlString(string):
                if let string {
                    return URL(string: string)
                }
                return nil
            }
        }()

        // 비동기 로딩 시작
        Task {
            await binder.start(url: url, options: options)

            // 결과 처리
            if let image = binder.loadedImage, let url {
                // 이미지 변환이 필요한 경우
                if options.transition != .none {
                    binder.animating = true
                    withAnimation(
                        Animation
                            .linear(duration: transitionDuration(for: options.transition))
                    ) {
                        binder.animating = false
                    }
                }

                // 성공 콜백 호출
                let result = ImageLoadingResult(image: image, url: url, originalData: Data())
                onSuccess?(result)
            } else if url != nil, binder.loadedImage == nil {
                // 실패 콜백 호출
                onFailure?(NeoImageError.responseError(reason: .invalidImageData))
            }
        }
    }

    private func transitionDuration(for transition: ImageTransition) -> TimeInterval {
        switch transition {
        case .none:
            return 0
        case let .fade(duration):
            return duration
        case let .flip(duration):
            return duration
        }
    }
}

// MARK: - View Extensions for NeoImage

/// NeoImage 생성을 위한 편의 확장
extension View {
    /// URL로부터 NeoImage를 생성하는 모디파이어
    public func neoImage(
        url: URL?,
        placeholder: AnyView? = nil,
        options: NeoImageOptions = .default
    ) -> some View {
        let neoImage = NeoImage(url: url)
            .options(options)

        if let placeholder {
            return neoImage.placeholder { placeholder }
        }

        return neoImage
    }

    /// URL 문자열로부터 NeoImage를 생성하는 모디파이어
    public func neoImage(
        urlString: String?,
        placeholder: AnyView? = nil,
        options: NeoImageOptions = .default
    ) -> some View {
        let neoImage = NeoImage(urlString: urlString)
            .options(options)

        if let placeholder {
            return neoImage.placeholder { placeholder }
        }

        return neoImage
    }
}
