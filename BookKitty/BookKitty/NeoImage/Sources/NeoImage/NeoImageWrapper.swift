import UIKit

// MARK: - Wrapper & Associated Object Key
nonisolated(unsafe) private var associatedImageTaskKey = "com.neoimage.UIImageView.ImageTask"

/// NeoImage 기능에 접근하기 위한 네임스페이스 역할을 하는 wrapper 구조체
public struct NeoImageWrapper<Base> {
    public let base: Base
    public init(_ base: Base) {
        self.base = base
    }
}

/// NeoImage의 기능을 제공받을 수 있는 타입들이 준수해야 하는 프로토콜
public protocol NeoImageCompatible: AnyObject { }

extension NeoImageCompatible {
    /// neo 네임스페이스를 통해 NeoImage의 기능에 접근
    public var neo: NeoImageWrapper<Self> {
        get { return NeoImageWrapper(self) }
        set { }
    }
}

extension UIImageView: NeoImageCompatible { }

// MARK: - UIImageView Extension

extension NeoImageWrapper where Base: UIImageView {
    @discardableResult
    public func setImage(
        with url: URL?,
        placeholder: UIImage? = nil,
        options: NeoImageOptions? = nil,
        progressBlock: ((Int64, Int64) -> Void)? = nil,
        completion: ((Result<ImageLoadingResult, Error>) -> Void)? = nil
    ) async -> ImageTask? {
        guard let url = url else {
            await MainActor.run {
                base.image = placeholder
            }
            completion?(.failure(CacheError.invalidData))
            return nil
        }
        
        // task 관리를 위한 로컬 변수
        let task = ImageTask()
        
        return await Task { [weak base] in
            guard let base = base else { return nil }
            
            // 기존 task가 있다면 취소
            await self.cancelDownloadTask()
            
            // placeholder 설정
            if let placeholder = placeholder {
                await MainActor.run {
                    base.image = placeholder
                }
            }
            
            await self.setImageDownloadTask(task)
            
            do {
                let result = try await ImageDownloadManager.shared.downloadImage(with: url)
                
                try Task.checkCancellation()
                
                // 이미지 처리 (백그라운드에서 수행)
                let processedImage = try await self.processImage(result.image, options: options)
                
                try Task.checkCancellation()
                
                // 캐시에 저장 (백그라운드에서 수행)
                if let data = processedImage.jpegData(compressionQuality: 0.8) {
                    try await ImageCache.shared.store(data, forKey: url.absoluteString)
                }
                
                try Task.checkCancellation()
                
                // UI 업데이트는 메인 스레드에서
                await MainActor.run {
                    base.image = processedImage
                    
                    // transition 효과 적용
                    if let transition = options?.transition {
                        self.applyTransition(transition)
                    }
                }
                
                let finalResult = ImageLoadingResult(
                    image: processedImage,
                    url: url,
                    originalData: result.originalData
                )
                
                completion?(.success(finalResult))
            } catch is CancellationError {
                completion?(.failure(CacheError.unknown(CancellationError())))
            } catch {
                completion?(.failure(error))
            }
            
            return task
        }.value
    }
    
    private func processImage(_ image: UIImage, options: NeoImageOptions?) async throws -> UIImage {
        // 이미지 프로세서가 있다면 처리 (백그라운드에서 수행)
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
    
    private func setImageDownloadTask(_ task: ImageTask?) async {
        await MainActor.run {
            objc_setAssociatedObject(
                base,
                &associatedImageTaskKey,
                task,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }
    
    private func getImageDownloadTask() async -> ImageTask? {
        await MainActor.run {
            objc_getAssociatedObject(base, &associatedImageTaskKey) as? ImageTask
        }
    }
    
    private func cancelDownloadTask() async {
        if let task = await getImageDownloadTask() {
            await task.cancel()
            await setImageDownloadTask(nil)
        }
    }
}

