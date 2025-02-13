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
public final class BookMatchKit: @preconcurrency BookMatchable {
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
    ///   - image: 도서 표지 이미지
    /// - Returns: 매칭된 도서 정보 또는 nil
    /// - Throws: 초기 단어부터 검색된 결과가 나오지 않을 때
    @MainActor
    public func matchBook(image: UIImage) -> Single<BookItem?> {
        print("🛠 matchBook(image:) 실행됨") // ✅ matchBook 함수 실행 확인

        let extractStream: Single<[String]> = Single.deferred { [weak self] in
            guard let self else {
                return .just([])
            }
            print("📌 OCR 실행 시도") // ✅ OCR 실행 직전 확인
            return extractText(from: image)
                .do(onSuccess: { text in
                    print("📑 OCR 추출 결과: \(text)")
                }, onError: { error in
                    print("⚠️ OCR 실행 중 오류 발생: \(error.localizedDescription)")
                })
        }

        let searchBook = { [weak self] (textData: [String]) -> Single<[BookItem]> in
            guard let self else {
                return .just([])
            }

            print("🔎 책 검색 시작: \(textData)")
            return fetchSearchResults(from: textData)
                .do(onSuccess: { books in
                    print("📚 검색된 책 목록: \(books.count)권")
                }, onError: { error in
                    print("⚠️ 책 검색 실패: \(error.localizedDescription)")
                })
        }

        let processBook = { [weak self] (book: BookItem) -> Single<(BookItem, Double)> in
            guard let self else {
                return .never()
            }

            print("📷 이미지 다운로드 시작: \(book.image)")

            return apiClient.downloadImage(from: book.image)
                .catch { error in
                    print("⚠️ 이미지 다운로드 실패: \(error.localizedDescription)")
                    return .error(BookMatchError.imageDownloadFailed)
                }
                .flatMap { downloadedImage in
                    print("🔎 유사도 비교 시작")
                    return self.imageStrategy.calculateSimilarity(image, downloadedImage)
                        .map { (book, $0) }
                        .catch { error in
                            print("⚠️ 유사도 계산 실패: \(error.localizedDescription)")
                            return .error(
                                BookMatchError
                                    .imageCalculationFailed(error.localizedDescription)
                            )
                        }
                }
        }

        return extractStream
            .flatMap { textData -> Single<[BookItem]> in
                print("📌 matchBook2 실행됨, OCR 결과: \(textData)")
                return searchBook(textData)
            }
            .flatMap { results -> Single<[BookItem]> in
                print("📌 matchBook3 실행됨, 검색 결과: \(results.count)권")
                if results.isEmpty {
                    return .error(BookMatchError.noMatchFound)
                }

                return .just(results)
            }
            .flatMap { books in
                print("📌 matchBook4 실행됨, 유사도 비교 진행")
                return Observable.from(books)
                    .flatMap { book in processBook(book).asObservable() }
                    .toArray()
            }
            .map { (results: [(BookItem, Double)]) -> BookItem? in
                print("📌 최종 유사도 비교 완료: \(results)")
                return results.sorted { $0.1 > $1.1 }.first?.0
            }
            .do(onSuccess: { matchedBook in
                if let book = matchedBook {
                    print("✅ 최종 매칭된 도서: \(book.title)")
                } else {
                    print("⚠️ 최종 매칭 실패")
                }
            }, onError: { error in
                print("❌ matchBook 실행 중 오류 발생: \(error.localizedDescription)")
            })
    }

    // MARK: - OCR Logic

    /// 이미지에서 텍스트를 추출하고, 추출된 텍스트를 반환합니다.
    /// - Parameter image: 텍스트를 추출할 이미지
    /// - Returns: 추출된 텍스트 배열
    @MainActor
    private func extractText(from image: UIImage) -> Single<[String]> {
        print("📌 extractText 실행됨!") // ✅ OCR 실행 확인

        return Single.create { single in
            Task { @MainActor in // ✅ 메인 스레드에서 실행
                print("📌 detectBookElements 호출 예정") // ✅ 실행 직전 확인
                self.detectBookElements(in: image) { extractedTexts in
                    print("📌 detectBookElements 결과: \(extractedTexts)") // ✅ OCR 결과 확인
                    single(.success(extractedTexts))
                }
            }
            return Disposables.create()
        }
    }

    /// 감지된 바운딩 박스를 확장하여 OCR 정확도를 높임
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
            print("⚠️ 원본 이미지의 CGImage를 가져올 수 없음, 원본 이미지 반환")
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
            print("⚠️ 이미지 크롭 실패, 원본 이미지로 OCR 진행")
            return image
        }
        return UIImage(cgImage: croppedCGImage)
    }

    /// CoreML을 사용하여 책 제목을 인식 후 OCR 실행
    @MainActor
    private func detectBookElements(in image: UIImage, completion: @escaping ([String]) -> Void) {
        print("📌 detectBookElements 실행됨!")

        guard let model = try? VNCoreMLModel(for: MyObjectDetector5_1().model) else {
            print("⚠️ CoreML 모델 로드 실패, OCR 강제 실행")
            performOCR(on: image, completion: completion)
            return
        }

        let request = VNCoreMLRequest(model: model) { request, error in
            if let error {
                print("⚠️ Vision 요청 실패: \(error.localizedDescription), OCR 강제 실행")
                self.performOCR(on: image, completion: completion)
                return
            }

            guard let results = request.results as? [VNRecognizedObjectObservation] else {
                print("⚠️ Vision 결과 없음, OCR 강제 실행")
                self.performOCR(on: image, completion: completion)
                return
            }

            // ✅ Confidence Threshold 완화
            let filteredResults = results.filter { $0.confidence > 0.3 } // 신뢰도 30% 이상
            if filteredResults.isEmpty {
                print("⚠️ 신뢰도 낮음, OCR 강제 실행")
                self.performOCR(on: image, completion: completion)
                return
            }

            print("📚 감지된 객체 수 (Threshold 적용): \(filteredResults.count)")

            var extractedTexts: [String] = []
            let dispatchGroup = DispatchGroup()

            for observation in filteredResults {
                let detectedLabel = observation.labels.first?.identifier ?? "Unknown"
                print("🔎 감지된 객체: \(detectedLabel)")

                if detectedLabel == "titles-or-authors" || detectedLabel == "book-title" {
                    dispatchGroup.enter()

                    let expandedBox = self.expandBoundingBox(observation.boundingBox, factor: 1.2)
                    let croppedImage = self.cropImage(image, to: expandedBox) ?? image

                    // ✅ 크롭된 이미지 디버깅용으로 확인
                    DispatchQueue.main.async {
                        let debugImageView = UIImageView(image: croppedImage)
                        debugImageView.frame = CGRect(x: 10, y: 100, width: 200, height: 200)
                        debugImageView.contentMode = .scaleAspectFit
                        UIApplication.shared.windows.first?.addSubview(debugImageView)
                    }

                    // ✅ 원본과 크롭된 이미지 모두 OCR 실행하여 더 좋은 결과 선택
                    self.performOCR(on: croppedImage) { croppedText in
                        self.performOCR(on: image) { originalText in
                            let finalText = croppedText.isEmpty ? originalText : croppedText
                            print("✅ OCR 실행 완료, 최종 결과: \(finalText)")
                            extractedTexts.append(contentsOf: finalText)
                            dispatchGroup.leave()
                        }
                    }
                }
            }

            dispatchGroup.notify(queue: .main) {
                print("📑 최종 OCR 텍스트: \(extractedTexts)")
                if extractedTexts.isEmpty {
                    print("⚠️ OCR 실패, 원본 이미지로 최종 OCR 실행")
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
            print("⚠️ Vision Request Error: \(error.localizedDescription), OCR 강제 실행")
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

    @MainActor
    private func performOCR(on image: UIImage, completion: @escaping ([String]) -> Void) {
        print("📌 performOCR 실행됨!")

        guard let preprocessedImage = convertToGrayscale(image),
              let cgImage = preprocessedImage.cgImage else {
            print("⚠️ 대비 조정 실패, 원본 이미지 사용")
            completion([])
            return
        }

        let request = VNRecognizeTextRequest { request, error in
            if let error {
                print("⚠️ OCR 오류 발생: \(error.localizedDescription)")
                completion([])
                return
            }

            guard let observations = request.results as? [VNRecognizedTextObservation],
                  !observations.isEmpty else {
                print("⚠️ OCR 결과 없음")
                completion([])
                return
            }

            let recognizedText = observations.compactMap { $0.topCandidates(1).first?.string }
            print("✅ OCR 인식된 텍스트: \(recognizedText)")
            completion(recognizedText)
        }

        request.recognitionLanguages = ["ko", "en"]
        request.usesLanguageCorrection = true
        request.minimumTextHeight = 0.005

        Task {
            let resizedImage = await preprocessedImage.resized(toWidth: 1024) ?? preprocessedImage
            print("📏 이미지 리사이징 완료: \(resizedImage.size)")

            await MainActor.run {
                let requestHandler = VNImageRequestHandler(
                    cgImage: resizedImage.cgImage!,
                    options: [:]
                )
                do {
                    print("📝 OCR 실행 중...")
                    try requestHandler.perform([request])
                } catch {
                    print("⚠️ OCR 요청 실패: \(error.localizedDescription)")
                    completion([])
                }
            }
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
}
