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

    private let imageStrategy = VisionImageStrategy()
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
            .flatMap { [weak self] textData -> Single<[BookItem]> in
                guard let self else {
                    return .error(BookMatchError.deinitError)
                }
                return fetchSearchResults(from: textData)
            }
            .flatMap { results -> Single<[BookItem]> in
                if results.isEmpty {
                    BookMatchLogger.errorOccurred(
                        BookMatchError.noMatchFound,
                        context: "Book Search"
                    )
                    return .error(BookMatchError.noMatchFound)
                }

                BookMatchLogger.searchResultsReceived(count: results.count)
                return .just(results)
            }
            // - Note: 여기서 books는 비어있을 수 없습니다.
            .flatMap { books in
                Observable.from(books)
                    .flatMap { [weak self] book -> Single<(BookItem, Double)> in
                        guard let self else {
                            return .error(BookMatchError.deinitError)
                        }

                        return imageDownloadAPI.downloadImage(from: book.image)
                            .catch { _ in
                                .error(BookMatchError.imageDownloadFailed)
                            }
                            .flatMap { [weak self] downloadedImage -> Single<(BookItem, Double)> in
                                guard let self else {
                                    return .error(BookMatchError.deinitError)
                                }

                                return imageStrategy.calculateSimilarity(image, downloadedImage)
                                    .map {
                                        BookMatchLogger.similarityCalculated(
                                            bookTitle: book.title,
                                            score: $0
                                        )
                                        return (book, $0)
                                    }
                            }
                    }
                    .asObservable()
                    .toArray()
            }
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

                Single<Void>.just(())
                    .delay(
                        .milliseconds(500),
                        scheduler: ConcurrentDispatchQueueScheduler(qos: .background)
                    )
                    .flatMap { [weak self] _ -> Single<[BookItem]> in
                        guard let self else {
                            return .error(BookMatchError.deinitError)
                        }

                        return naverAPI.searchBooks(query: currentQuery, limit: 10)
                    }
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
    private func extractText(from image: UIImage) -> Single<[String]> {
        Single.create { single in
            self.detectBookElements(in: image) { extractedTexts in
                single(.success(extractedTexts))
            }
            return Disposables.create()
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

    /// CoreML을 사용하여 책 제목을 인식 후 OCR 실행
    private func detectBookElements(in image: UIImage, completion: @escaping ([String]) -> Void) {
        guard let model = try? VNCoreMLModel(for: MyObjectDetector5_1().model) else {
            performOCR(on: image, completion: completion)
            return
        }

        let request = VNCoreMLRequest(model: model) { request, error in
            if let error {
                self.performOCR(on: image, completion: completion)
                return
            }

            guard let results = request.results as? [VNRecognizedObjectObservation] else {
                self.performOCR(on: image, completion: completion)
                return
            }

            let filteredResults = results.filter { $0.confidence > 0.3 } // 신뢰도 30% 이상
            if filteredResults.isEmpty {
                self.performOCR(on: image, completion: completion)
                return
            }

            var extractedTexts: [String] = []
            let dispatchGroup = DispatchGroup()

            for observation in filteredResults {
                let detectedLabel = observation.labels.first?.identifier ?? "Unknown"

                if detectedLabel == "titles-or-authors" || detectedLabel == "book-title" {
                    dispatchGroup.enter()

                    let expandedBox = self.expandBoundingBox(observation.boundingBox, factor: 1.2)
                    let croppedImage = self.cropImage(image, to: expandedBox)

                    self.performOCR(on: croppedImage) { croppedText in
                        self.performOCR(on: image) { originalText in
                            let finalText = croppedText.isEmpty ? originalText : croppedText
                            extractedTexts.append(contentsOf: finalText)
                            dispatchGroup.leave()
                        }
                    }
                }
            }

            dispatchGroup.notify(queue: .main) {
                if extractedTexts.isEmpty {
                    self.performOCR(on: image, completion: completion)
                } else {
                    completion(extractedTexts)
                }
            }
        }

        do {
            let handler = VNImageRequestHandler(cgImage: image.cgImage!, options: [:])
            try handler.perform([request])
        } catch let error as NSError {
            performOCR(on: image, completion: completion)
        }
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

    private func performOCR(on image: UIImage, completion: @escaping ([String]) -> Void) {
        guard let preprocessedImage = convertToGrayscale(image),
              let cgImage = preprocessedImage.cgImage else {
            completion([])
            return
        }

        let request = VNRecognizeTextRequest { request, error in
            if let error {
                completion([])
                return
            }

            guard let observations = request.results as? [VNRecognizedTextObservation],
                  !observations.isEmpty else {
                completion([])
                return
            }

            // 텍스트 크기 순서대로 정렬
            let sortedObservations = observations.sorted { obs1, obs2 in
                let size1 = obs1.boundingBox.width * obs1.boundingBox.height
                let size2 = obs2.boundingBox.width * obs2.boundingBox.height
                return size1 > size2 // 크기가 큰 순서대로 정렬
            }

            // 정렬된 텍스트 추출
            let recognizedText = sortedObservations.compactMap { $0.topCandidates(1).first?.string }
            print("✅ OCR 인식된 텍스트 (크기 순서대로): \(recognizedText)")
            completion(recognizedText)
        }

        request.recognitionLanguages = ["ko", "en"]
        request.usesLanguageCorrection = true
        request.minimumTextHeight = 0.005

        let requestHandler = VNImageRequestHandler(
            cgImage: preprocessedImage.cgImage!,
            options: [:]
        )
        do {
            try requestHandler.perform([request])
        } catch {
            completion([])
        }
    }
}
