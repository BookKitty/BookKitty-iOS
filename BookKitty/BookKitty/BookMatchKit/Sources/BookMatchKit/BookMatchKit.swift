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

        // 구독이 발생할 때까지 Single의 생성을 지연시키는 팩토리 메서드
        // 클로저 내부에서 두가지 경우 just([]), fetchSearchResults()의 Single을 반환하고 있어 정확한 타입을 추론하기 어려워 함 -> 타입
        // 모호성 에러 발생 -> 반환 타입 명시적으로 지정 필요
        // let searchStream = Single.deferred { [weak self] in
        //     guard let self else { return .just([]) }
        //     return self.fetchSearchResults(from: rawData.flatMap { $0 })
        // }

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
            // 빈 결과 체크
            .flatMap { results -> Single<[BookItem]> in
                if results.isEmpty {
                    return .error(BookMatchError.noMatchFound)
                }
                return .just(results)
            }
            // 각 책에 대한 이미지 비교 작업을 Observable로 변환
            .flatMap { books in
                Observable.from(books)
                    .flatMap { book in processBook(book).asObservable() }
                    .toArray()
            }
            .map { results in
                results.sorted { $0.1 > $1.1 }
                    .first?.0
            }
            // 에러 처리
            .catch { error in
                print("Error in matchBook: \(error)")
                return .just(nil)
            }
    }

    /// `OCR로 검출된 텍스트 배열`로 도서를 검색합니다.
    /// - Note:``matchBook(_:, image:)`` 메서드에 사용됩니다.
    ///
    /// - Parameters:
    ///   - sourceBook: 검색할 도서의 기본 정보
    /// - Returns: 검색된 도서 목록
    /// - Throws: BookMatchError
    ///
    /// `Single`: RxSwift에서 단 하나의 값을 방출하고, 에러나 완료를 방출하는 `Observable` 의 특별한 형태
    private func fetchSearchResults(from textData: [String]) -> Single<[BookItem]> {
        // 인자값이 비어있으면 빈 배열을 Single로 즉시 반환
        // ```
        // public static func just(_ element: Element) -> Single<Element> {
        //     Single(raw: Observable.just(element))
        // }
        // ```

        guard !textData.isEmpty else {
            // 주어진 값을 즉시 방출하고 완료되는 Single을 생성
            return .just([])
        }

        // ``Observable`` 스트림을 새로 생성, `observer`는 값을 방출하고 완료/에러를 알릴 수 있는 `이벤트 발생기`
        // 검색어를 하나씩 추가해가며 `여러 번의 값 방출이 필요하기 때문`에, Single을 최종 반환하더라도 `Observable`을 초기에 생성
        return Single<[BookItem]>.create { single in
            var searchResults = [BookItem]()
            var previousResults = [BookItem]()
            var currentIndex = 0
            var currentQuery = ""

            // 다음 쿼리를 처리하는 내부 함수
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

                // 스트림을 시작하기 위한 트리거로써 Single<Int> 사용 / Void는 의미 없는 값임을 명시적으로 나타냄
                Single<Void>.just(())
                    .delay(
                        .milliseconds(500),
                        scheduler: ConcurrentDispatchQueueScheduler(qos: .background)
                    )
                    // `flatMap`: Single 시퀀스의 각 항목을 다른 Single로 변환하고, 그 결과들을 하나의 Single로
                    // 평탄화(flatten)하는 연산자
                    // Timer Single에서 searchBooks api의 결과값에 대한 Single로 스트림을 전환
                    .flatMap { _ in
                        self.apiClient
                            .searchBooks(query: currentQuery, limit: 10) // Single<[BookItem]>을 반환
                    }
                    .subscribe(
                        onSuccess: { results in // API 결과를 구독하여 처리
                            if !results.isEmpty {
                                previousResults = results
                            }
                            // 결과가 3개 이하면 이전 결과를 최종 결과로 사용하고 완료
                            if results.count <= 3 {
                                searchResults = previousResults
                                single(.success(searchResults))
                                // 마지막 텍스트를 처리한 경우, 현재 결과가 있으면 그것을, 없으면 이전 결과를 사용하고 완료합니다.
                            } else if currentIndex == textData.count - 1 {
                                searchResults = results.isEmpty ? previousResults : results
                                single(.success(searchResults))
                                // 그 외의 경우 다음 텍스트 처리를 진행
                            } else {
                                currentIndex += 1
                                processNextQuery()
                            }
                        }, onFailure: { error in
                            // 에러가 발생하면 에러를 전파
                            single(.failure(error))
                        }
                    )
                    // 구독을 disposeBag에 추가하여 메모리 관리
                    .disposed(by: self.disposeBag)
            }

            processNextQuery()

            // ``Disposables.create()``
            // Single.create나 Observable.create를 사용할 때 `필수적으로` 반환해야 하는 값입니다.
            // - Disposable을 반환함으로써, 구독이 해제될 때 필요한 정리 작업을 수행할 수 있습니다. 이는 구독이 해제될 때 진행중인 작업을 취소하고 리소스
            // 정리가 가능하게 합니다

            // 현재 코드에서는 구독 해제 시 필요로 하는 특별한 정리 작업이 필요가 없습니다.
            // 하지만, 컴파일 에러를 방지하고자 해당 메서드를 호출합니다.
            return Disposables.create()
        }
    }
}
