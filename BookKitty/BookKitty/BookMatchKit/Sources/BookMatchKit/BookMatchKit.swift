import BookMatchAPI
import BookMatchCore
import BookMatchStrategy
import CoreFoundation
import RxSwift
import UIKit

@_exported import struct BookMatchCore.OwnedBook

/// 도서 `매칭` 기능의 핵심 모듈입니다.
/// 사용자의 요청을 처리하고, 도서 검색, `매칭` 기능을 조율합니다.
public final class BookMatchKit: BookMatchable {
    // MARK: Lifecycle

    public init(
        naverClientId: String,
        naverClientSecret: String,
        naverBaseURL _: String = "https://openapi.naver.com/v1/search/book.json"
    ) {
        let config = APIConfiguration(
            naverClientId: naverClientId,
            naverClientSecret: naverClientSecret,
            openAIApiKey: ""
        )

        apiClient = DefaultAPIClient(configuration: config)
    }

    // MARK: Public

    /// `OCR로 인식된 텍스트 데이터와 이미지`를 기반으로 실제 도서를 `매칭`합니다.
    ///
    /// - Parameters:
    ///   - rawData: OCR로 인식된 텍스트 데이터 배열
    ///   - image: 도서 표지 이미지
    /// - Returns: 매칭된 도서 정보 또는 nil
    public func matchBook(_ rawData: [[String]], image: UIImage) -> Single<BookItem?> {
        let textData = rawData.flatMap { $0 }

        return fetchSearchResults(from: textData)
            .flatMap { searchResults -> Single<BookItem?> in
                guard !searchResults.isEmpty else {
                    return .error(BookMatchError.noMatchFound)
                }

                return Observable.from(searchResults)
                    .flatMap { [weak self] book -> Observable<(BookItem, Double)> in
                        guard let self else {
                            return Observable.empty()
                        }
                        return apiClient.downloadImage(from: book.image)
                            .flatMap { downloadedImage in
                                self.imageStrategy.calculateSimilarity(image, downloadedImage)
                                    .map { similarity in
                                        (book, similarity)
                                    }
                            }
                            .asObservable()
                    }
                    .toArray() // 이미 Array 반환함
                    .map { similarityResults -> BookItem? in
                        let sortedResults = similarityResults.sorted { $0.1 > $1.1 }
                        return sortedResults.first?.0
                    }
            }
            .catch { error in
                print("error in procesBookMatch: \(error)")
                return .just(nil)
            }
    }

    // MARK: Private

    private let imageStrategy = VisionImageStrategy()
    private let apiClient: APIClientProtocol
    private let disposeBag = DisposeBag()

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

        return Observable.create { observer in
            var searchResults = [BookItem]()
            var previousResults = [BookItem]()
            var currentIndex = 0
            var currentQuery = ""

            func processNextQuery() {
                guard currentIndex < textData.count else {
                    observer.onNext(searchResults)
                    observer.onCompleted()
                    return
                }

                if currentQuery.isEmpty {
                    currentQuery = textData[currentIndex]
                } else {
                    currentQuery = [currentQuery, textData[currentIndex]].joined(separator: " ")
                }

                // Rate limit 방지를 위한 딜레이 추가
                Observable<Int>
                    .timer(
                        .milliseconds(500),
                        scheduler: ConcurrentDispatchQueueScheduler(qos: .background)
                    )
                    .flatMap { _ in
                        self.apiClient.searchBooks(query: currentQuery, limit: 10).asObservable()
                    }
                    .subscribe(onNext: { results in
                        if !results.isEmpty {
                            previousResults = results
                        }

                        if results.count <= 3 {
                            searchResults = previousResults
                            observer.onNext(searchResults)
                            observer.onCompleted()
                        } else if currentIndex == textData.count - 1 {
                            searchResults = results.isEmpty ? previousResults : results
                            observer.onNext(searchResults)
                            observer.onCompleted()
                        } else {
                            currentIndex += 1
                            processNextQuery()
                        }
                    }, onError: { error in
                        observer.onError(error)
                    })
                    .disposed(by: self.disposeBag)
            }

            processNextQuery()

            return Disposables.create()
        }
        .asSingle()
    }
}
