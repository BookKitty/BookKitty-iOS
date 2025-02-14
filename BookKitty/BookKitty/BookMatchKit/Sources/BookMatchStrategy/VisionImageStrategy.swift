import BookMatchCore
import RxSwift
import UIKit
import Vision

/// 도서 표지 이미지 간의 유사도를 계산하는 클래스입니다.
/// Vision 프레임워크를 사용하여 이미지의 특징점을 추출하고 비교합니다.
public class VisionImageStrategy: SimilarityCalculatable {
    // MARK: - Nested Types

    // MARK: - Public

    public typealias T = UIImage

    // MARK: - Properties

    // MARK: - Private

    private let disposeBag = DisposeBag()
    private let context = CIContext()

    // MARK: - Lifecycle

    public init() {}

    // MARK: - Functions

    /// 두 이미지 간의 `유사도를 계산`합니다.
    ///
    /// - Parameters:
    ///   - image1: 비교할 첫 번째 이미지
    ///   - imageURL2: 비교할 두 번째 이미지의 URL
    /// - Returns: 0부터 100 사이의 유사도 점수 (높을수록 유사)
    public func calculateSimilarity(_ image1: UIImage, _ image2: UIImage) -> Single<Double> {
        Single.create { single in
            let processedImage1 = self.preprocessImage(image1)
            let processedImage2 = self.preprocessImage(image2)

            do {
                let featurePrint1 = try self.extractFeaturePrint(from: processedImage1)
                let featurePrint2 = try self.extractFeaturePrint(from: processedImage2)

                var distance: Float = 0.0
                try featurePrint1.computeDistance(&distance, to: featurePrint2)
                let similarity = max(0, min(1, 2.5 - distance * 2.5))

                single(.success(Double(similarity)))
            } catch {
                single(.success(Double(-1.0)))
            }

            return Disposables.create()
        }
    }

    /// 이미지로부터 특징점을 추출합니다.
    ///
    /// - Parameters:
    ///   - image: 특징점을 추출할 이미지
    /// - Returns: 추출된 특징점 데이터
    /// - Throws: BookMatchError.imageCalculationFailed
    private func extractFeaturePrint(from image: UIImage) throws
        -> VNFeaturePrintObservation {
        guard let ciImage = CIImage(image: image) else {
            throw BookMatchError.networkError
        }

        let requestHandler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        let request = VNGenerateImageFeaturePrintRequest()

        do {
            try requestHandler.perform([request])
        } catch {
            throw error
        }
        guard let featurePrint = request.results?.first as? VNFeaturePrintObservation else {
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
