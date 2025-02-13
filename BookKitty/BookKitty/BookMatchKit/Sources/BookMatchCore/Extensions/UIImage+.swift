import UIKit

extension UIImage {
    @MainActor
    public func resized(toWidth width: CGFloat) -> UIImage? {
        let scaleFactor = width / size.width
        let canvasSize = CGSize(width: width, height: size.height * scaleFactor)

        UIGraphicsBeginImageContextWithOptions(canvasSize, false, UIScreen.main.scale)
        defer { UIGraphicsEndImageContext() }

        draw(in: CGRect(origin: .zero, size: canvasSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
