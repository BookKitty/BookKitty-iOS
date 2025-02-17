import BookMatchCore
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
            // `flatMap` - CoreML 결과를 OCR 처리로 변환
            // - Note: 객체 인식 결과를 필터링하고 각 영역에 대해 OCR을 수행.
            //         신뢰도가 낮거나 결과가 없는 경우 전체 이미지에 대한 OCR 수행.
            .flatMap { observations -> Single<[String]> in
                let filteredResults = observations.filter { $0.confidence > 0.3 }

                if filteredResults.isEmpty {
                    return .error(BookMatchError.CoreMLError("No Result from CoreML"))
                }

                // `Observable.from` - 필터링된 결과를 개별 스트림으로 변환
                // - Note: 각 인식된 영역에 대해 순차적으로 OCR을 수행.
                //         concatMap을 사용하여 순차적 처리 보장.
                return Observable.from(filteredResults)
                    .filter { observation in
                        let detectedLabel = observation.labels.first?.identifier ?? "Unknown"
                        return detectedLabel == "titles-or-authors" || detectedLabel == "book-title"
                    }
                    // `concatMap` - 각 영역에 대한 순차적 OCR 수행
                    .concatMap { [weak self] observation -> Single<[String]> in
                        guard let self else {
                            return .error(BookMatchError.deinitError)
                        }
                        let expandedBox = imageProcessService.expandBoundingBox(
                            observation.boundingBox,
                            factor: 1.2
                        )
                        let croppedImage = imageProcessService.cropImage(image, to: expandedBox)

                        // 크롭된 이미지와 원본 이미지에 대한 OCR 순차 처리
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
        // `Single.create` - CoreML 모델 로드 및 Vision 요청 처리를 래핑
        // - Note: 비동기적인 Vision 프레임워크 호출을 RxSwift Single로 변환.
        //         성공 시 텍스트 배열, 실패 시 전체 이미지 OCR 수행.
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
        // `Single.create` - Vision OCR 요청을 래핑
        // - Note: Vision 프레임워크의 텍스트 인식 프로세스를 RxSwift Single로 변환.
        //         에러 발생 시 이전 코드와 동일하게 빈 배열 반환.
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
}
