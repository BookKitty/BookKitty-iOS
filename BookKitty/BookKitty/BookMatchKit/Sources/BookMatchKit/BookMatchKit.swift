import AVFoundation
import BookMatchAPI
import BookMatchCore
import BookMatchStrategy
import CoreFoundation
import CoreML
import DesignSystem
import RxCocoa
import RxCocoaRuntime
import RxSwift
import SnapKit
import Then
import UIKit
import Vision

@_exported import struct BookMatchCore.OwnedBook

/// 도서 `매칭` 기능의 핵심 모듈입니다.
/// 사용자의 요청을 처리하고, 도서 검색, `매칭` 기능을 조율합니다.
public final class BookMatchKit: BookMatchable {
    // MARK: - Properties

    // MARK: - Private

    private let imageStrategy = VisionImageStrategy()
    private let apiClient: APIClientProtocol
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

        apiClient = DefaultAPIClient(configuration: config)
    }

    // MARK: - Functions

    // MARK: - Public

    /// `OCR로 인식된 텍스트 데이터와 이미지`를 기반으로 실제 도서를 `매칭`합니다.
    ///
    /// - Parameters:
    ///   - rawData: OCR로 인식된 텍스트 데이터 배열
    ///   - image: 도서 표지 이미지
    /// - Returns: 매칭된 도서 정보 또는 nil
    public func matchBook(_ rawData: [[String]], image: UIImage) -> Single<BookItem?> {
        let textData = rawData.flatMap { $0 }

        let searchStream: Single<[BookItem]> = Single.deferred { [weak self] in
            guard let self else {
                return .just([])
            }
            return fetchSearchResults(from: textData)
        }

        let processBook = { [weak self] (book: BookItem) -> Single<(BookItem, Double)> in
            guard let self else {
                return .never()
            }

            return apiClient.downloadImage(from: book.image)
                .flatMap { downloadedImage in
                    self.imageStrategy.calculateSimilarity(image, downloadedImage)
                        .map { (book, $0) }
                }
        }

        return searchStream
            .flatMap { results -> Single<[BookItem]> in
                if results.isEmpty {
                    return .error(BookMatchError.noMatchFound)
                }
                return .just(results)
            }
            .flatMap { books in
                Observable.from(books)
                    .flatMap { book in processBook(book).asObservable() }
                    .toArray()
            }
            .map { results in
                results.sorted { $0.1 > $1.1 }
                    .first?.0
            }
            .catch { error in
                print("Error in matchBook: \(error)")
                return .just(nil)
            }
    }

    // MARK: - OCR Logic

    /// 이미지에서 텍스트를 추출하고, 추출된 텍스트를 반환합니다.
    /// - Parameter image: 텍스트를 추출할 이미지
    /// - Returns: 추출된 텍스트 배열
    public func extractText(from image: UIImage) -> Single<[String]> {
        Single.create { single in
            self.detectBookElements(in: image) { extractedTexts in
                single(.success(extractedTexts))
            }
            return Disposables.create()
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
                            return .error(BookMatchError.noMatchFound)
                        }
                        return apiClient.searchBooks(query: currentQuery, limit: 10)
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

    private func detectBookElements(in image: UIImage, completion: @escaping ([String]) -> Void) {
        guard let model = try? VNCoreMLModel(for: MyObjectDetector5_1().model) else {
            print("⚠️ CoreML 모델 로드 실패")
            completion([])
            return
        }

        let request = VNCoreMLRequest(model: model) { request, error in
            if let error {
                print("⚠️ Vision 요청 실패: \(error.localizedDescription)")
                completion([])
                return
            }

            guard let results = request.results as? [VNRecognizedObjectObservation] else {
                print("⚠️ Vision 결과 없음")
                completion([])
                return
            }

            var extractedTexts: [String] = []
            let dispatchGroup = DispatchGroup()

            for observation in results
                where observation.labels.first?.identifier == "titles-or-authors" {
                dispatchGroup.enter()
                self.performOCR(on: image) { recognizedText in
                    if !recognizedText.isEmpty {
                        extractedTexts.append(recognizedText)
                    }
                    dispatchGroup.leave()
                }
            }

            dispatchGroup.notify(queue: .main) {
                completion(extractedTexts)
            }
        }

        request.usesCPUOnly = true
        request.preferBackgroundProcessing = true

        do {
            let handler = VNImageRequestHandler(cgImage: image.cgImage!, options: [:])
            try handler.perform([request])
        } catch let error as NSError {
            print("⚠️ Vision Request Error: \(error.localizedDescription)")
            completion([])
        }
    }

    private func performOCR(on image: UIImage, completion: @escaping (String) -> Void) {
        guard let cgImage = image.cgImage else {
            print("⚠️ 이미지 변환 실패")
            completion("")
            return
        }

        let request = VNRecognizeTextRequest { request, error in
            if let error {
                print("⚠️ OCR 오류 발생: \(error.localizedDescription)")
                completion("")
                return
            }

            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                print("⚠️ OCR 결과 없음")
                completion("")
                return
            }

            let recognizedText = observations.compactMap { $0.topCandidates(1).first?.string }
                .joined(separator: " ")
            print("✅ OCR 결과: \(recognizedText)")
            completion(recognizedText)
        }

        request.recognitionLanguages = ["ko", "en"]
        request.usesLanguageCorrection = true
        request.minimumTextHeight = 0.002

        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try requestHandler.perform([request])
        } catch {
            print("⚠️ OCR 요청 실패: \(error.localizedDescription)")
            completion("")
        }
    }
}

// MARK: - UIImage Extension (리사이즈 기능 추가)

extension UIImage {
    @MainActor
    func resized(toWidth width: CGFloat) -> UIImage? {
        let scaleFactor = width / size.width
        let canvasSize = CGSize(width: width, height: size.height * scaleFactor)

        UIGraphicsBeginImageContextWithOptions(canvasSize, false, UIScreen.main.scale)
        defer { UIGraphicsEndImageContext() }

        draw(in: CGRect(origin: .zero, size: canvasSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
