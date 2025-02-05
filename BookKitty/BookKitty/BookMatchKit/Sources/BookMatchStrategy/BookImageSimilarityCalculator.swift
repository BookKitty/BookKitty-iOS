import BookMatchCore
import UIKit
import Vision

/// 도서 표지 이미지 간의 유사도를 계산하는 클래스입니다.
/// Vision 프레임워크를 사용하여 이미지의 특징점을 추출하고 비교합니다.
public class BookImageSimilarityCalculator: ImageSimilarityCalculatable {
    // MARK: Lifecycle

    public init(
        session: URLSession = .shared,
        context: CIContext = CIContext()
    ) {
        self.session = session
        self.context = context
    }

    // MARK: Public

    /// 두 이미지 간의 `유사도를 계산`합니다.
    ///
    /// - Parameters:
    ///   - image1: 비교할 첫 번째 이미지
    ///   - imageURL2: 비교할 두 번째 이미지의 URL
    /// - Returns: 0부터 100 사이의 유사도 점수 (높을수록 유사)
    public func calculateImageSimilarity(image1: UIImage, imageURL2: String) async -> Double {
        do {
            let image2 = try await downloadImage(from: imageURL2)

            let processedImage1 = preprocessImage(image1)
            let processedImage2 = preprocessImage(image2)

            guard let featurePrint1 = try? await extractFeaturePrint(from: processedImage1),
                  let featurePrint2 = try? await extractFeaturePrint(from: processedImage2) else {
                throw BookMatchError.imageCalculationFailed("FeaturePrint 생성 실패 2")
            }

            var distance: Float = 0.0
            try featurePrint1.computeDistance(&distance, to: featurePrint2)
            let similarity = max(0, min(100, (2.5 - distance * 2.5) * 100))

            return Double(similarity)
        } catch {
            print("유사도 연산 실패, \(error)")
            return -1.0
        }
    }

    // MARK: Private

    private let session: URLSession
    private let context: CIContext

    /// URL로부터 이미지를 다운로드합니다.
    ///
    /// - Parameters:
    ///   - urlString: 이미지 URL 문자열
    /// - Returns: 다운로드된 UIImage
    /// - Throws: BookMatchError.networkError
    private func downloadImage(from urlString: String) async throws -> UIImage {
        guard let url = URL(string: urlString) else {
            throw BookMatchError.networkError("Invalid URL")
        }

        let (data, _) = try await session.data(from: url)

        guard let image = UIImage(data: data) else {
            print("UIImage")
            throw BookMatchError.networkError("Image Fetch Failed")
        }

        return image
    }

    /// 이미지로부터 특징점을 추출합니다.
    ///
    /// - Parameters:
    ///   - image: 특징점을 추출할 이미지
    /// - Returns: 추출된 특징점 데이터
    /// - Throws: BookMatchError.imageCalculationFailed
    private func extractFeaturePrint(from image: UIImage) async throws
        -> VNFeaturePrintObservation {
        guard let ciImage = CIImage(image: image) else {
            throw BookMatchError.networkError("Image Fetch Failed")
        }

        let requestHandler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        let request = VNGenerateImageFeaturePrintRequest()

        do {
            try requestHandler.perform([request])
        } catch {
            print("VNImageRequestHandler failed: \(error)")
            throw error
        }
        guard let featurePrint = request.results?.first as? VNFeaturePrintObservation else {
            print("Results: \(String(describing: request.results))")
            throw BookMatchError.imageCalculationFailed("FeaturePrint 생성 실패 1")
        }

        return featurePrint
    }

    /// 이미지 전처리를 수행합니다.
    /// 대비를 보정하고 크기를 조정합니다.
    ///
    /// - Parameters:
    ///   - image: 전처리할 이미지
    /// - Returns: 전처리된 이미지
    private func preprocessImage(_ image: UIImage) -> UIImage {
        guard let ciImage = CIImage(image: image) else {
            return image
        }

        guard let filter = CIFilter(name: "CIColorControls") else { return image }

        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(1.3, forKey: kCIInputContrastKey) // 대비 증가
        filter.setValue(0.05, forKey: kCIInputBrightnessKey) // 밝기 조정

        guard let outputImage = filter.outputImage,
              let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return image
        }

        return UIImage(cgImage: cgImage)
    }
}
