import UIKit

// MARK: - Wrapper & Associated Object Key

/// UIImageView가 NeoImage의 기능을 제공받을 수 있는 NeoImageCompatible 프로토콜을 채택할 수 있음을 명시합니다.
extension UIImageView: NeoImageCompatible {}

public protocol NeoImageCompatible: AnyObject {}

extension NeoImageCompatible {
    /// neo 네임스페이스를 통해 NeoImage의 기능에 접근할 수 있습니다.
    public var neo: NeoImageWrapper<UIImageView> {
        get { NeoImageWrapper(self as! UIImageView) }
        set {}
    }
}

/// NeoImage 기능에 접근하기 위한 네임스페이스 역할을 하는 wrapper 구조체
public struct NeoImageWrapper<Base: Sendable>: Sendable {
    // MARK: - Properties

    public let base: Base

    // MARK: - Lifecycle

    /// 여기서 Base는 이미지 캐시 및 이미지 데이터가 주입되는 UIImageView를 의미합니다.
    public init(_ base: Base) {
        self.base = base
    }
}

// MARK: - UIImageView Extension

extension NeoImageWrapper where Base: UIImageView {
    @discardableResult // Return type을 strict하게 확인하지 않습니다.
    private func setImageAsync(
        with url: URL?,
        placeholder: UIImage? = nil,
        options: NeoImageOptions? = nil
    ) async throws -> (ImageLoadingResult, ImageTask?) {
        // 이미지뷰가 실제로 화면에 표시되어 있는지 여부 파악,
        // 이는 Swift 6로 오면서 비동기 작업으로 간주되기 시작함.
        guard await base.window != nil else {
            throw CacheError.invalidData
        }

        if let placeholder {
            await MainActor.run { [weak base] in
                guard let base else {
                    return
                }
                base.image = placeholder
            }
        }
        // TODO: gray로 차선책 placeholder 렌더 넣기

        guard let url else {
            throw CacheError.invalidData
        }

        // TODO: ImageTask 연결하기
        // UIImageView에 연결된 ImageTask를 가져옵니다
        // 현재 진행 중인 다운로드 작업이 있는지 확인하는데 사용됩니다
        if let task = objc_getAssociatedObject(
            base,
            NeoImageConstants.associatedKey
        ) as? ImageTask {
            await task.cancel()
            await setImageDownloadTask(nil)
        }

        let imageTask = ImageTask()
        await setImageDownloadTask(imageTask)

        // NeoImageManager를 사용해 이미지 다운로드 (캐시 확인 + 이미지 후처리)
        let downloadResult = try await NeoImageManager.shared.downloadImage(
            with: url,
            options: options
        )
        try Task.checkCancellation()

        // UI 업데이트
        await MainActor.run { [weak base] in
            guard let base else {
                return
            }
            base.image = downloadResult.image
            applyTransition(to: base, with: options?.transition)
        }
//        imageTask.setDownloadTask(down)
        return (downloadResult, imageTask)
    }

    // MARK: - Wrapper

    /// `Public Async API`
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

    /// `Public Completion Handler API`
    @discardableResult
    public func setImage(
        with url: URL?,
        placeholder: UIImage? = nil,
        options: NeoImageOptions? = nil,
        completion: (@MainActor @Sendable (Result<ImageLoadingResult, Error>) -> Void)? = nil
    ) -> ImageTask? {
        let task = ImageTask()

        Task { @MainActor in
            do {
                let (result, _) = try await setImageAsync(
                    with: url,
                    placeholder: placeholder,
                    options: options
                )

                completion?(.success(result))
            } catch {
                await task.fail()
                completion?(.failure(error))
            }
        }

        return task
    }

    @MainActor
    private func applyTransition(to imageView: UIImageView, with transition: ImageTransition?) {
        guard let transition else {
            return
        }

        switch transition {
        case .none:
            break
        case let .fade(duration):
            UIView.transition(
                with: imageView,
                duration: duration,
                options: .transitionCrossDissolve,
                animations: nil,
                completion: nil
            )
        case let .flip(duration):
            UIView.transition(
                with: imageView,
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
        // 모든 NSObject의 하위 클래스에 대해 사용할 수 있는 메서드이며, SWift에서는 @obj 마킹이 된 클래스도 대상으로 설정이 가능합니다.
        // 순수 Swift 타입인 struct와 enum, class에는 사용이 불가하기 때문에, NSObject를 상속하거나 @objc 속성을 사용해야 합니다.
        // - `UIView` 및 모든 하위 클래스
        // - UIViewController 및 모든 하위 클래스
        // - UIApplication
        // - UIGestureRecognizer
        // Foundation 클래스들
        // - `NSString`
        // - NSArray
        // - NSDictionary
        // - URLSession

        objc_setAssociatedObject(
            base, // 대상 객체 (UIImageView)
            NeoImageConstants.associatedKey, // 키 값
            task, // 저장할 값
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC // 메모리 관리 정책
        )
    }
}
