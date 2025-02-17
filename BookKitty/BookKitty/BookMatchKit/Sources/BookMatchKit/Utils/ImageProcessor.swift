import UIKit

public class ImageProcessor: ImageProcessable {
    // MARK: - Lifecycle

    public init() {}

    // MARK: - Functions

    /// 감지된 바운딩 박스를 확장하여 OCR 정확도를 높임
    public func expandBoundingBox(_ boundingBox: CGRect, factor: CGFloat) -> CGRect {
        let x = boundingBox.origin.x - (boundingBox.width * (factor - 1)) / 2
        let y = boundingBox.origin.y - (boundingBox.height * (factor - 1)) / 2
        let width = boundingBox.width * factor
        let height = boundingBox.height * factor

        return CGRect(
            x: max(0, x),
            y: max(0, y),
            width: min(1, width),
            height: min(1, height)
        )
    }

    /// 감지된 영역을 크롭하여 OCR 정확도를 높임
    public func cropImage(_ image: UIImage, to boundingBox: CGRect) -> UIImage {
        guard let cgImage = image.cgImage else {
            return image
        }
        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)

        let cropRect = CGRect(
            x: boundingBox.origin.x * width,
            y: boundingBox.origin.y * height,
            width: boundingBox.width * width,
            height: boundingBox.height * height
        )

        guard let croppedCGImage = cgImage.cropping(to: cropRect) else {
            return image
        }
        return UIImage(cgImage: croppedCGImage)
    }

    public func convertToGrayscale(_ image: UIImage) -> UIImage? {
        guard let ciImage = CIImage(image: image) else {
            return nil
        }

        let filter = CIFilter(name: "CIColorControls")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(1.5, forKey: kCIInputContrastKey) // 대비 증가
        filter?.setValue(0.0, forKey: kCIInputSaturationKey) // 채도 제거 (흑백)

        guard let outputImage = filter?.outputImage else {
            return nil
        }
        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent)
        else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }
}
