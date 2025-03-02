import UIKit

public enum FilteringAlgorithm: Sendable {
    case none
    case linear
    case trilinear
}

/// 이미지 처리를 위한 프로토콜
public protocol ImageProcessing: Sendable {
    /// 이미지를 처리하는 메서드
    func process(_ image: UIImage) async throws -> UIImage

    /// 프로세서의 식별자
    /// 캐시 키 생성에 사용됨
    var identifier: String { get }
}

/// 이미지 리사이징 프로세서
public struct ResizingImageProcessor: ImageProcessing {
    // MARK: - Properties

    /// 대상 크기
    private let targetSize: CGSize

    /// 크기 조정 모드
    private let contentMode: UIView.ContentMode

    /// 크기 조정 시 필터링 방식
    private let filteringAlgorithm: FilteringAlgorithm

    // MARK: - Computed Properties

    public var identifier: String {
        let contentModeString: String = {
            switch contentMode {
            case .scaleToFill: return "ScaleToFill"
            case .scaleAspectFit: return "ScaleAspectFit"
            case .scaleAspectFill: return "ScaleAspectFill"
            default: return "Unknown"
            }
        }()

        return "com.neoimage.ResizingImageProcessor(\(targetSize),\(contentModeString))"
    }

    // MARK: - Lifecycle

    public init(
        targetSize: CGSize,
        contentMode: UIView.ContentMode = .scaleToFill,
        filteringAlgorithm: FilteringAlgorithm = .linear
    ) {
        self.targetSize = targetSize
        self.contentMode = contentMode
        self.filteringAlgorithm = filteringAlgorithm
    }

    // MARK: - Functions

    public func process(_ image: UIImage) async throws -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale

        let size = calculateTargetSize(image.size)
        let renderer = UIGraphicsImageRenderer(size: size, format: format)

        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    private func calculateTargetSize(_ originalSize: CGSize) -> CGSize {
        switch contentMode {
        case .scaleToFill:
            return targetSize

        case .scaleAspectFit:
            let widthRatio = targetSize.width / originalSize.width
            let heightRatio = targetSize.height / originalSize.height
            let ratio = min(widthRatio, heightRatio)
            return CGSize(
                width: originalSize.width * ratio,
                height: originalSize.height * ratio
            )

        case .scaleAspectFill:
            let widthRatio = targetSize.width / originalSize.width
            let heightRatio = targetSize.height / originalSize.height
            let ratio = max(widthRatio, heightRatio)
            return CGSize(
                width: originalSize.width * ratio,
                height: originalSize.height * ratio
            )

        default:
            return targetSize
        }
    }
}

/// 둥근 모서리 처리를 위한 프로세서
public struct RoundCornerImageProcessor: ImageProcessing {
    // MARK: - Properties

    /// 모서리 반경
    private let radius: CGFloat

    // MARK: - Computed Properties

    public var identifier: String {
        "com.neoimage.RoundCornerImageProcessor(\(radius))"
    }

    // MARK: - Lifecycle

    public init(radius: CGFloat) {
        self.radius = radius
    }

    // MARK: - Functions

    public func process(_ image: UIImage) async throws -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale

        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: image.size)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: radius)

            context.cgContext.addPath(path.cgPath)
            context.cgContext.clip()

            image.draw(in: rect)
        }
    }
}

/// 여러 프로세서를 순차적으로 적용하는 프로세서
public struct ChainImageProcessor: ImageProcessing {
    // MARK: - Properties

    private let processors: [ImageProcessing]

    // MARK: - Computed Properties

    public var identifier: String {
        processors.map(\.identifier).joined(separator: "|")
    }

    // MARK: - Lifecycle

    public init(_ processors: [ImageProcessing]) {
        self.processors = processors
    }

    // MARK: - Functions

    public func process(_ image: UIImage) async throws -> UIImage {
        var processedImage = image
        for processor in processors {
            processedImage = try await processor.process(processedImage)
        }
        return processedImage
    }
}
