import BookMatchCore
import CoreImage
import NaturalLanguage
import RxSwift
import UIKit
import Vision

public final class TextExtractionService: TextExtractable {
    // MARK: - Properties

    private let imageProcessService: ImageProcessable = ImageProcessService()

    // MARK: - Lifecycle

    public init() {}

    // MARK: - Functions

    // MARK: - OCR Logic

    /// 이미지에서 텍스트를 추출하고, 추출된 텍스트를 반환합니다.
    /// - Parameter image: 텍스트를 추출할 이미지
    /// - Returns: 추출된 텍스트 배열
    /// CoreML을 사용하여 책 제목을 인식 후 OCR 실행
    public func extractText(from image: UIImage) -> Single<[String]> {
        getObservationFromCoreML(for: image)
            .flatMap { observations -> Single<[String]> in
                let filteredResults = observations.filter { $0.confidence > 0.3 }

                if filteredResults.isEmpty {
                    return .error(BookMatchError.CoreMLError("No Result from CoreML"))
                }

                return Observable.from(filteredResults)
                    .filter { observation in
                        let detectedLabel = observation.labels.first?.identifier ?? "Unknown"
                        return detectedLabel == "titles-or-authors" || detectedLabel == "book-title"
                    }
                    .concatMap { [weak self] observation -> Single<[String]> in
                        guard let self else {
                            return .error(BookMatchError.deinitError)
                        }
                        let expandedBox = imageProcessService.expandBoundingBox(
                            observation.boundingBox,
                            factor: 1.2
                        )
                        let croppedImage = imageProcessService.cropImage(image, to: expandedBox)

                        return performOCR(on: croppedImage)
                            .flatMap { croppedText -> Single<[String]> in
                                if croppedText.isEmpty {
                                    return self.performOCR(on: image)
                                }
                                return .just(croppedText)
                            }
                    }
                    .toArray()
                    .flatMap { arrays in
                        let texts = arrays.flatMap { $0 }
                        guard !texts.isEmpty else {
                            return .error(BookMatchError.CoreMLError("No Result from CoreML"))
                        }

                        BookMatchLogger.textsExtracted(texts)
                        return .just(texts)
                    }
            }
            .catch { [weak self] error in
                guard let self else {
                    return .error(BookMatchError.deinitError)
                }

                BookMatchLogger.error(error, context: "extract Text")

                return performOCR(on: image)
            }
    }

    private func getObservationFromCoreML(for image: UIImage)
        -> Single<[VNRecognizedObjectObservation]> {
        Single<[VNRecognizedObjectObservation]>.create { single in
            do {
                let config = MLModelConfiguration()
                let objectDetector = try MyObjectDetector5_1(configuration: config)
                let model = try VNCoreMLModel(for: objectDetector.model)

                let handler = VNImageRequestHandler(cgImage: image.cgImage!, options: [:])

                let request = VNCoreMLRequest(model: model) { request, error in
                    if let error {
                        single(.failure(
                            BookMatchError
                                .CoreMLError("Error in request: \(error.localizedDescription)")
                        ))
                        return
                    }

                    guard let results = request.results as? [VNRecognizedObjectObservation] else {
                        single(.failure(BookMatchError.CoreMLError("Invalid results format")))
                        return
                    }

                    single(.success(results))
                }

                try handler.perform([request])

            } catch {
                single(.failure(BookMatchError.CoreMLError(error.localizedDescription)))
            }

            return Disposables.create()
        }
    }

    /// Vision 프레임워크를 사용하여 이미지에서 텍스트를 인식
    private func performOCR(on image: UIImage) -> Single<[String]> {
        Single<[String]>.create { single in
            guard let cgImage = self.imageProcessService.convertToGrayscale(image)?.cgImage
            else {
                single(.failure(BookMatchError.OCRError("convertToGrayscale Failed")))
                return Disposables.create()
            }

            let requestHandler = VNImageRequestHandler(
                cgImage: cgImage,
                options: [:]
            )

            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    single(.failure(
                        BookMatchError
                            .OCRError("Error in request: \(error.localizedDescription)")
                    ))
                    return
                }

                guard let results = request.results as? [VNRecognizedTextObservation] else {
                    single(.failure(BookMatchError.OCRError("Invalid results format")))
                    return
                }

                let sortedObservations = results.sorted { obs1, obs2 in
                    let size1 = obs1.boundingBox.width * obs1.boundingBox.height
                    let size2 = obs2.boundingBox.width * obs2.boundingBox.height
                    return size1 > size2
                }

                let recognizedText = sortedObservations.compactMap {
                    $0.topCandidates(1).first?.string
                }

                BookMatchLogger.textExtracted(recognizedText)
                single(.success(recognizedText))
            }

            request.recognitionLanguages = ["ko", "en"]
            request.usesLanguageCorrection = true
            request.minimumTextHeight = 0.005

            do {
                try requestHandler.perform([request])
            } catch {
                single(.failure(BookMatchError.OCRError("perform")))
            }

            return Disposables.create()
        }
        .catch { error in
            BookMatchLogger.error(error, context: "performOCR")
            return .just([])
        }
    }

    // MARK: - Image Enhancement

    private func preprocessImage(_ image: UIImage) -> UIImage {
        guard let ciImage = CIImage(image: image) else {
            return image
        }

        // 1. Contrast Limited AHE
        let clahe = ciImage.applyingFilter("CICLAHE", parameters: ["inputClipLimit": 0.03])

        // 2. Adaptive Threshold
        let threshold = clahe.applyingFilter(
            "CIColorThreshold",
            parameters: ["inputThreshold": 0.8]
        )

        // 3. Noise Reduction
        let denoised = threshold.applyingFilter("CIMedianFilter")
            .applyingFilter("CIMorphologyMinimum", parameters: ["inputRadius": 1.2])

        // 4. Sharpening
        let sharpened = denoised.applyingFilter("CISharpenLuminance", parameters: [
            "inputSharpness": 0.95,
            "inputRadius": 1.8,
        ])

        // 5. Skew Correction
        let corrected = correctSkew(in: sharpened)

        guard let cgImage = CIContext().createCGImage(corrected, from: corrected.extent)
        else {
            return image
        }
        return UIImage(cgImage: cgImage)
    }

    // MARK: - Skew Correction

    private func correctSkew(in image: CIImage) -> CIImage {
        guard let detector = CIDetector(
            ofType: CIDetectorTypeRectangle,
            context: nil,
            options: nil
        ) else {
            BookMatchLogger.detectorInitializationFailed()
            return image
        }

        guard let feature = detector.features(in: image).first as? CIRectangleFeature else {
            BookMatchLogger.textSlopeDetectionFailed()
            return image
        }

        // 각도 계산 (좌상단과 우상단 점을 사용하여 기울기 추정)
        let dx = feature.topRight.x - feature.topLeft.x
        let dy = feature.topRight.y - feature.topLeft.y
        let angle = atan2(dy, dx)

        return image.applyingFilter("CIAffineTransform", parameters: [
            kCIInputTransformKey: NSValue(
                cgAffineTransform: CGAffineTransform(rotationAngle: -angle)
            ),
        ])
    }

    // MARK: - Text Analysis

    private func analyzeTextStructure(_ observations: [VNRecognizedTextObservation]) -> String {
        var textBlocks = [(rect: CGRect, text: String)]()

        for obs in observations {
            guard let text = obs.topCandidates(1).first?.string else {
                continue
            }
            textBlocks.append((obs.boundingBox, text))
        }

        let lineGroups = Dictionary(grouping: textBlocks) { Int($0.rect.midY * 1000) }
        return lineGroups.values
            .sorted { ($0.first?.rect.minY ?? 0) < ($1.first?.rect.minY ?? 0) }
            .map { $0.sorted { $0.rect.minX < $1.rect.minX }.map(\.text).joined(separator: " ") }
            .joined(separator: "\n")
    }

    // MARK: - Korean Correction

    private func correctKoreanText(_ text: String) -> String {
        let replacements: [String: String] = [
            "뛌끼": "뜨끼", "햐야": "해야", "따릉": "따름",
            "(\\b\\w+\\b) \\1": "$1", // 반복 단어 제거
            "(?<=[가-힣])\\s+(?=[을를이가])": "", // 조사 띄어쓰기 교정
        ]

        var corrected = text
        for (key, value) in replacements {
            corrected = corrected.replacingOccurrences(
                of: key,
                with: value,
                options: .regularExpression
            )
        }
        return corrected
    }

    // MARK: - Pattern Filtering

    private func applyPatternFilters(_ text: String) -> String {
        let patterns = [
            "(ISBN|isbn).*?\\d{1,5}-\\d{1,7}-\\d{1,7}-\\d", // ISBN 번호 필터링
            "\\d{4}[년.-]\\s*\\d{1,2}[월.-]\\s*\\d{1,2}일?", // 날짜 형식 필터링
            "http[s]?://(?:[a-zA-Z]|[0-9]|[$-_@.&+]|[!*\\(\\),]|(?:%[0-9a-fA-F][0-9a-fA-F]))+",
            // URL 필터링
        ]

        return text.components(separatedBy: .newlines)
            .filter { line in
                !patterns.contains { line.range(of: $0, options: .regularExpression) != nil }
            }
            .joined(separator: "\n")
    }
}
