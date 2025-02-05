import UIKit

public protocol ImageSimilarityCalculatable {
    func calculateImageSimilarity(image1: UIImage, imageURL2: String) async -> Double
}
