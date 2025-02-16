import UIKit

public protocol ImageProcessable {
    func convertToGrayscale(_ image: UIImage) -> UIImage?
    func cropImage(_ image: UIImage, to boundingBox: CGRect) -> UIImage
    func expandBoundingBox(_ boundingBox: CGRect, factor: CGFloat) -> CGRect
}
