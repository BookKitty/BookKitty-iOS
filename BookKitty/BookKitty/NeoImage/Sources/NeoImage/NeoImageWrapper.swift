import UIKit

// MARK: - Wrapper & Associated Object Key

/// UIImageView가 NeoImage의 기능을 제공받을 수 있는 NeoImageCompatible 프로토콜을 채택할 수 있음을 명시합니다.
extension UIImageView: NeoImageCompatible { }

public protocol NeoImageCompatible: AnyObject { }

extension NeoImageCompatible {
    /// neo 네임스페이스를 통해 NeoImage의 기능에 접근할 수 있습니다.
    public var neo: NeoImageWrapper<Self> {
        get { return NeoImageWrapper(self) }
        set { }
    }
}

/// NeoImage 기능에 접근하기 위한 네임스페이스 역할을 하는 wrapper 구조체
public struct NeoImageWrapper<Base> {
    public let base: Base
    /// 여기서 Base는 이미지 캐시 및 이미지 데이터가 주입되는 UIImageView를 의미합니다.
    public init(_ base: Base) {
        self.base = base
    }
}

// MARK: - UIImageView Extension

extension NeoImageWrapper where Base: UIImageView {
    @discardableResult /// Return type을 strict하게 확인하지 않습니다.
    private func setImageAsync(
        with url: URL?,
        placeholder: UIImage? = nil,
        options: NeoImageOptions? = nil
    ) async throws -> (ImageLoadingResult, ImageTask?) {
        /// 초기에 외부에서 주입받은 UIImageView 컴포넌트입니다.
        let baseView = base
        
        /// Data race 상황이 발생하지 않게끔 현재 컨텍스트를 imageWrapper에 캡처합니다.
        let imageWrapper = self
        
        /// 메인 스레드에 실행
        return try await Task { @MainActor in
            guard let url = url else {
                baseView.image = placeholder
                throw CacheError.invalidData
            }
            
            guard baseView.window != nil else {
                throw CacheError.invalidData
            }
            
            if let placeholder = placeholder {
                /// 우선 ImageView에 placeholder를 주입합니다.
                baseView.image = placeholder
            }
            
            /// 현재 컨텍스트에서 발생하고 있는 다운로드 작업을 취소하여 초기화합니다.
            await imageWrapper.cancelDownloadTask()
            
            /// 이미지 다운로드 작업을 관리하는 클래스를 새로 생성합니다.
            let task = ImageTask()
            
            await imageWrapper.setImageDownloadTask(task)

            /// 이미지 다운로드
            let result = try await ImageDownloadManager.shared.downloadImage(with: url)
            /// 도중에 Task가 취소된 경우 에러를 throw하도록 합니다.
            try Task.checkCancellation()
            
            /// 이미지 리사이징
            let processedImage = try await imageWrapper.processImage(result.image, options: options)
            try Task.checkCancellation()
            
            /// jpegData가 존재할 경우, 이를 바로 이미지 캐시(메모리 & 디스크)에 저장 및 보관합니다.
            if let data = processedImage.jpegData(compressionQuality: 0.8) {
                try await ImageCache.shared.store(data, forKey: url.absoluteString)
            }
            
            try Task.checkCancellation()
            
            /// 리사이즈를 거친 최종 이미지 데이터를 UIImageView의 image 속성에 주입시켜 이미지를 렌더하도록 합니다.
            baseView.image = processedImage
            
            /// Transition 존재할 경우, 그대로 UIImageView에 적용
            if let transition = options?.transition {
                imageWrapper.applyTransition(transition)
            }
            
            let finalResult = ImageLoadingResult(
                image: processedImage,
                url: url,
                originalData: result.originalData
            )
            
            return (finalResult, task)
        }.value
    }
    
    // MARK: - Public Async API
    
    /// async/await 패턴이 적용된 환경에서 사용가능한 래퍼 메서드입니다.
    public func setImage(
        with url: URL?,
        placeholder: UIImage? = nil,
        options: NeoImageOptions? = nil
    ) async throws -> ImageLoadingResult {
        let (result, _) = try await setImageAsync(
            with: url,
            placeholder: placeholder,
            options: options
        )
        
        return result
    }
    
    // MARK: - Public Completion Handler API
    
    @discardableResult
    public func setImage(
        with url: URL?,
        placeholder: UIImage? = nil,
        options: NeoImageOptions? = nil,
        completion: ((Result<ImageLoadingResult, Error>) -> Void)? = nil
    ) async -> ImageTask? {
        do {
            let (result, task) = try await setImageAsync(
                with: url,
                placeholder: placeholder,
                options: options
            )
            
            completion?(.success(result))
            return task
        } catch {
            completion?(.failure(error))
            return nil
        }
    }
    
    private func processImage(_ image: UIImage, options: NeoImageOptions?) async throws -> UIImage {
        if let processor = options?.processor {
            return try await processor.process(image)
        }
        
        return image
    }
    
    @MainActor
    private func applyTransition(_ transition: ImageTransition) {
        switch transition {
        case .none:
            break
        case .fade(let duration):
            UIView.transition(
                with: base,
                duration: duration,
                options: .transitionCrossDissolve,
                animations: nil,
                completion: nil
            )
        case .flip(let duration):
            UIView.transition(
                with: base,
                duration: duration,
                options: .transitionFlipFromLeft,
                animations: nil,
                completion: nil
            )
        }
    }
    
    // MARK: - Task Management
    
    /// UIImageView는 기본적으로 ImageTask를 저장할 프로퍼티가 없습니다.
    ///
    /// 따라서, Objective-C의 런타임 기능을 사용해 UIImageView 인스턴스에 ImageTask를 동적으로 연결하여 저장합니다,
    /// 현재 진행중인 이미지 다운로드 작업 추적에 사용됩니다.
    private func setImageDownloadTask(_ task: ImageTask?) async {
        await MainActor.run {
            /// 모든 NSObject의 하위 클래스에 대해 사용할 수 있는 메서드이며, SWift에서는 @obj 마킹이 된 클래스도 대상으로 설정이 가능합니다.
            /// 순수 Swift 타입인 struct와 enum, class에는 사용이 불가하기 때문에, NSObject를 상속하거나 @objc 속성을 사용해야 합니다.
            /// - `UIView` 및 모든 하위 클래스
            /// - UIViewController 및 모든 하위 클래스
            /// - UIApplication
            /// - UIGestureRecognizer
            /// Foundation 클래스들
            /// - `NSString`
            /// - NSArray
            /// - NSDictionary
            /// - URLSession
            
            objc_setAssociatedObject(
                base, // 대상 객체 (UIImageView)
                ImageTaskKey.associatedKey,  // 키 값
                task,  // 저장할 값
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC  // 메모리 관리 정책
            )
        }
    }
    
    /// UIImageView에 연결된 ImageTask를 가져옵니다
    /// 현재 진행 중인 다운로드 작업이 있는지 확인하는데 사용됩니다
    private func getImageDownloadTask() async -> ImageTask? {
        await MainActor.run {
            objc_getAssociatedObject(base, ImageTaskKey.associatedKey) as? ImageTask
        }
    }
    
    private func cancelDownloadTask() async {
        if let task = await getImageDownloadTask() {
            await task.cancel()
            await setImageDownloadTask(nil)
        }
    }
}

