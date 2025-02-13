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
    ///   - rawData: OCR로 인식된 텍스트 데이터 배열
    ///   - image: 도서 표지 이미지
    /// - Returns: 매칭된 도서 정보 또는 nil
    /// - Throws:초기 단어부터 검색된 결과가 나오지 않을때
    public func matchBook(image: UIImage) -> Single<BookItem?> {
        print("matchBook1")
        let extractStream: Single<[String]> = Single.deferred { [weak self] in
            guard let self else {
                return .just([])
            }

            return extractText(from: image)
        }

        let searchBook = { [weak self] (textData: [String]) -> Single<[BookItem]> in
            guard let self else {
                return .just([])
            }

            print("searchBook, textData: ", textData)
            return fetchSearchResults(from: textData)
        }

        let processBook = { [weak self] (book: BookItem) -> Single<(BookItem, Double)> in
            guard let self else {
                return .never()
            }

            return imageDownloadAPI.downloadImage(from: book.image)
                .catch { _ in
                    print("error in imageDownloadFailed")
                    return .error(BookMatchError.imageDownloadFailed)
                }
                .flatMap { downloadedImage in
                    self.imageStrategy.calculateSimilarity(image, downloadedImage)
                        .map { (book, $0) }
                        .catch { error in
                            print("error in imageCalculationFailed")
                            return .error(
                                BookMatchError
                                    .imageCalculationFailed(error.localizedDescription)
                            )
                        }
                }
        }

        return extractStream
            .flatMap { textData -> Single<[BookItem]> in
                print("matchBook2", textData)
                return searchBook(textData)
            }
            .flatMap { results -> Single<[BookItem]> in
                print("matchBook3")
                if results.isEmpty {
                    return .error(BookMatchError.noMatchFound)
                }

                return .just(results)
            }
            .flatMap { books in
                print("matchBook4")
                return Observable.from(books)
                    .flatMap { book in processBook(book).asObservable() }
                    .toArray()
            }
            .map { (results: [(BookItem, Double)]) -> BookItem? in
                results.sorted { $0.1 > $1.1 }
                    .first?.0
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

            print("📚 감지된 객체 수: \(results.count)")

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
                print("📑 최종 추출된 텍스트: \(extractedTexts)")
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
}
