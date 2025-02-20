import BookMatchAPI
import BookMatchCore
import RxSwift

public final class BookSearchService: BookSearchable {
    // MARK: - Properties

    private let naverAPI: NaverAPI
    private let disposeBag = DisposeBag()

    // MARK: - Lifecycle

    public init(naverAPI: NaverAPI) {
        self.naverAPI = naverAPI
    }

    // MARK: - Functions

    /// `제목 & 저자`로 도서를 검색합니다.
    /// - Note: ``convertToRealBook()`` 메서드에 사용됩니다.
    ///
    /// - Parameters:
    ///   - sourceBook: 검색할 도서의 기본 정보
    /// - Returns: 검색된 도서 목록
    /// - Throws: BookMatchError
    public func searchByTitleAndAuthor(from sourceBook: RawBook) -> Single<[BookItem]> {
        // `Observable.just` - 초기 값 스트림 생성
        // - Note: 검색 작업을 시작하기 위한 초기 트리거를 생성할 때 사용.
        //         실제 값보다는 검색 시작을 알리는 신호로 활용.
        //         title과 author로 병렬 검색을 수행하기 위해 Observable 사용
        Observable<Void>.just(())
            // `delay` - API 호출 지연
            // - Note: 연속적인 API 호출 사이에 지연을 추가할 때 사용.
            //         서버 부하를 줄이고 안정적인 검색 수행을 위해 500ms 지연 추가.
            .delay(
                .milliseconds(500),
                scheduler: ConcurrentDispatchQueueScheduler(qos: .background)
            )
            // `flatMap` - 병렬 검색 수행
            // - Note: 제목과 저자 검색을 동시에 수행할 때 사용.
            //         두 검색을 병렬로 처리하여 성능 최적화.
            .flatMap { [weak self] _ -> Observable<[BookItem]> in
                guard let self else {
                    return .error(BookMatchError.noMatchFound)
                }
                // title 검색과 author 검색을 동시에 수행
                let titleSearch = naverAPI.searchBooks(query: sourceBook.title, limit: 10)
                    .asObservable()
                let authorSearch = naverAPI.searchBooks(query: sourceBook.author, limit: 10)
                    .asObservable()

                // `zip` - 병렬 검색 결과 결합
                // - Note: 제목 검색과 저자 검색 결과를 하나로 합칠 때 사용.
                //         두 검색이 모두 완료된 후 결과를 통합.
                return Observable.zip(titleSearch, authorSearch)
                    // `map` - 검색 결과 병합
                    // - Note: 두 검색 결과를 하나의 배열로 합칠 때 사용.
                    //         중복을 허용하여 모든 검색 결과를 포함.
                    .map { titleResults, authorResults in
                        var searchedResults = [BookItem]()
                        searchedResults.append(contentsOf: titleResults)
                        searchedResults.append(contentsOf: authorResults)
                        return searchedResults
                    }
            }
            .asSingle()
            // `flatMap` - 추가 검색 조건 처리
            // - Note: 검색 결과가 없을 때 대체 검색을 수행할 때 사용.
            //         부제목을 제외한 메인 제목으로 재검색 수행.
            .flatMap { searchedResults -> Single<[BookItem]> in
                let subTitleDivider = [":", "|", "-"]
                // If no results and title contains divider, try searching with main title only
                if searchedResults.isEmpty,
                   !subTitleDivider.filter({ sourceBook.title.contains($0) }).isEmpty,
                   let divider = subTitleDivider.first(where: { sourceBook.title.contains($0) }),
                   let title = sourceBook.title.split(separator: divider).first {
                    return self.naverAPI.searchBooks(query: String(title), limit: 10)
                }

                return .just(searchedResults)
            }
    }

    /// `OCR로 검출된 텍스트 배열`로 도서를 검색합니다.
    /// - Note:``matchBook(_:, image:)`` 메서드에 사용됩니다.
    ///
    /// - Parameters:
    ///   - sourceBook: 검색할 도서의 기본 정보
    /// - Returns: 검색된 도서 목록
    /// - Throws: BookMatchError
    public func searchProgressively(from textData: [String]) -> Single<[BookItem]> {
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
                return self.naverAPI.searchBooks(query: currentQuery, limit: 10)
                    .delay(
                        .milliseconds(500),
                        scheduler: ConcurrentDispatchQueueScheduler(qos: .background)
                    )
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
    
    public func searchByQuery(from query: String) -> Single<[BookItem]> {
        return naverAPI.searchBooks(query: query, limit: 10)
    }
}
