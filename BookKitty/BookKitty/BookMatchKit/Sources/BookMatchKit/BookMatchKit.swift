import AVFoundation
import BookMatchAPI
import BookMatchCore
import BookMatchStrategy
import CoreFoundation
import CoreML
import RxSwift
import UIKit
import Vision

@_exported import struct BookMatchCore.OwnedBook

/// 도서 `매칭` 기능의 핵심 모듈입니다.
/// 사용자의 요청을 처리하고, 도서 검색, `매칭` 기능을 조율합니다.
public final class BookMatchKit: BookMatchable {
    // MARK: - Properties

    private let naverAPI: NaverAPI
    private let imageDownloadAPI: ImageDownloadAPI
    private let disposeBag = DisposeBag()

    // MARK: - Lifecycle

    public init(
        naverClientId: String,
        naverClientSecret: String
    ) {
        let config = APIConfiguration(
            naverClientId: naverClientId,
            naverClientSecret: naverClientSecret,
            openAIApiKey: ""
        )

        naverAPI = NaverAPI(configuration: config)
        imageDownloadAPI = ImageDownloadAPI(configuration: config)
    }

    // MARK: - Functions

    // MARK: - Public

    /// `OCR로 인식된 텍스트 데이터와 이미지`를 기반으로 실제 도서를 `매칭`합니다.
    ///
    /// - Parameters:
    ///   - image: 도서 표지 이미지
    /// - Returns: 매칭된 도서 정보 또는 nil
    /// - Throws: 초기 단어부터 검색된 결과가 나오지 않을 때
    public func matchBook(_ image: UIImage) -> Single<BookItem> {
        BookMatchLogger.matchingStarted()

        return extractText(from: image)
            // `flatMap` - 텍스트 추출 결과를 도서 검색 결과로 변환
            // - Note: OCR로 추출된 텍스트를 사용하여 `도서 검색을 수행`할 때 사용.
            //         텍스트 배열을 받아서 새로운 Single<[BookItem]> 스트림을 생성.
            //         메모리 해제 검사와 빈 결과 처리도 함께 수행.
            .flatMap { [weak self] textData -> Single<[BookItem]> in
                guard let self else {
                    return .error(BookMatchError.deinitError)
                }

                return fetchSearchResults(from: textData)
                    .flatMap { results in
                        guard !results.isEmpty else { // 유의미한 책 검색결과가 나오지 않았을 경우, 에러를 반환합니다
                            BookMatchLogger.error(
                                BookMatchError.noMatchFound,
                                context: "Book Search"
                            )

                            return .error(BookMatchError.noMatchFound)
                        }

                        BookMatchLogger.searchResultsReceived(count: results.count)
                        return .just(results)
                    }
            }
            // `flatMap` - 검색된 도서들에 대해 이미지 유사도 계산
            // - Note: 각 검색 결과에 대해 `이미지를 다운로드`하고 유사도를 계산할 때 사용.
            //         Observable.from()으로 배열을 개별 요소로 분리하고,
            //         flatMap으로 각 도서에 대한 이미지 다운로드와 유사도 계산을 수행.
            .flatMap { books in
                Observable.from(books)
                    .flatMap { [weak self] book -> Single<(BookItem, Double)> in
                        guard let self else {
                            return .error(BookMatchError.deinitError)
                        }

                        // - Note: imageDownloadFailed 에러를 반환할 수 있는 메서드입니다.
                        return imageDownloadAPI.downloadImage(from: book.image)
                            .flatMap { downloadedImage -> Single<(BookItem, Double)> in
                                let similarity = ImageVisionStrategy.calculateSimilarity(
                                    image,
                                    downloadedImage
                                )

                                BookMatchLogger.similarityCalculated(
                                    bookTitle: book.title,
                                    score: similarity
                                )

                                return .just((book, similarity))
                            }
                    }
                    // `toArray` - 개별 결과들을 배열로 변환
                    // - Note: 각각의 (BookItem, Double) 튜플을 하나의  `배열로 모을 때` 사용.
                    //         모든 이미지 유사도 계산이 완료된 후 한 번에 결과를 처리하기 위함.
                    .toArray()
            }
            // `map` - 최종 결과 변환
            // - Note: 유사도가 계산된 도서들 중 가장 높은 유사도를 가진 도서를 선택할 때 사용.
            //         sorted로 유사도 기준 내림차순 정렬 후 첫 번째 도서 선택.
            .map { (results: [(BookItem, Double)]) -> BookItem in
                guard let bestMatchedBook = results.sorted(by: { $0.1 > $1.1 }).first?.0 else {
                    throw BookMatchError.noMatchFound
                }

                BookMatchLogger.matchingCompleted(success: true, bookTitle: bestMatchedBook.title)
                return bestMatchedBook
            }
    }

    /// `OCR로 검출된 텍스트 배열`로 도서를 검색합니다.
    /// - Note:``matchBook(_:, image:)`` 메서드에 사용됩니다.
    ///
    /// - Parameters:
    ///   - sourceBook: 검색할 도서의 기본 정보
    /// - Returns: 검색된 도서 목록
    /// - Throws: BookMatchError
    private func fetchSearchResults(from textData: [String]) -> Single<[BookItem]> {
        guard !textData.isEmpty else {
            return .just([])
        }

        return Single<[BookItem]>.create { single in
            var searchResults = [BookItem]()
            var previousResults = [BookItem]()
            var currentIndex = 0
            var currentQuery = ""

            func processNextQuery() {
                guard currentIndex < textData.count else {
                    single(.success(searchResults))
                    return
                }

                if currentQuery.isEmpty {
                    currentQuery = textData[currentIndex]
                } else {
                    currentQuery = [currentQuery, textData[currentIndex]].joined(separator: " ")
                }

                // `delay` - API 호출 간 지연 시간 추가
                // - Note: 연속적인 API 호출 시 서버 부하를 줄이기 위해 사용.
                //         백그라운드 스레드에서 500ms 지연 후 다음 요청 실행.
                Single<Void>.just(())
                    .delay(
                        .milliseconds(500),
                        scheduler: ConcurrentDispatchQueueScheduler(qos: .background)
                    )
                    // `flatMap` - 지연 후 실제 검색 수행
                    // - Note: 지연 완료 후 실제 `도서 검색 API를 호출`할 때 사용.
                    //         메모리 해제 검사도 함께 수행.
                    .flatMap { [weak self] _ -> Single<[BookItem]> in
                        guard let self else {
                            return .error(BookMatchError.deinitError)
                        }

                        return naverAPI.searchBooks(query: currentQuery, limit: 10)
                    }
                    // `subscribe` - 검색 결과 처리 및 다음 검색 준비
                    // - Note: 검색 결과를 받아 처리하고 조건에 따라 다음 검색을 수행하거나 최종 결과를 반환할 때 사용.
                    //         성공/실패 케이스를 각각 처리하고 disposeBag으로 구독 해제 보장.
                    .subscribe(
                        onSuccess: { results in
                            if !results.isEmpty {
                                previousResults = results
                            }
                            if results.count <= 3 {
                                searchResults = previousResults
                                single(.success(searchResults))
                            } else if currentIndex == textData.count - 1 {
                                searchResults = results.isEmpty ? previousResults : results
                                single(.success(searchResults))
                            } else {
                                currentIndex += 1
                                processNextQuery()
                            }
                        }, onFailure: { error in
                            single(.failure(error))
                        }
                    )
                    .disposed(by: self.disposeBag)
            }

            processNextQuery()

            return Disposables.create()
        }
    }

    // MARK: - OCR Logic

    /// 이미지에서 텍스트를 추출하고, 추출된 텍스트를 반환합니다.
    /// - Parameter image: 텍스트를 추출할 이미지
    /// - Returns: 추출된 텍스트 배열
    /// CoreML을 사용하여 책 제목을 인식 후 OCR 실행
    private func extractText(from image: UIImage) -> Single<[String]> {
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
            //         concatMap을 사용하여 이전 코드의 순차적 처리 보장.
            return Observable.from(filteredResults)
                .filter { observation in
                    let detectedLabel = observation.labels.first?.identifier ?? "Unknown"
                    return detectedLabel == "titles-or-authors" || detectedLabel == "book-title"
                }
                // `concatMap` - 각 영역에 대한 순차적 OCR 수행
                // - Note: 각 영역을 순차적으로 처리하여 이전 코드의 동작 방식 유지.
                .concatMap { [weak self] observation -> Single<[String]> in
                    guard let self else {
                        return .error(BookMatchError.deinitError)
                    }
                    let expandedBox = expandBoundingBox(observation.boundingBox, factor: 1.2)
                    let croppedImage = cropImage(image, to: expandedBox)

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

    /// Vision 프레임워크를 사용하여 이미지에서 텍스트를 인식
    private func performOCR(on image: UIImage) -> Single<[String]> {
        // `Single.create` - Vision OCR 요청을 래핑
        // - Note: Vision 프레임워크의 텍스트 인식 프로세스를 RxSwift Single로 변환.
        //         에러 발생 시 이전 코드와 동일하게 빈 배열 반환.
        Single<[String]>.create { single in
            guard let cgImage = self.convertToGrayscale(image)?.cgImage else {
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

    /// 감지된 바운딩 박스를 확장하여 OCR 정확도를 높임
    private func expandBoundingBox(_ boundingBox: CGRect, factor: CGFloat) -> CGRect {
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
    private func cropImage(_ image: UIImage, to boundingBox: CGRect) -> UIImage {
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

    private func convertToGrayscale(_ image: UIImage) -> UIImage? {
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
