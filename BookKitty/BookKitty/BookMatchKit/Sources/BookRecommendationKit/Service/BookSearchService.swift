import BookMatchAPI
import BookMatchCore
import RxSwift

public final class BookSearchService {
    // MARK: - Properties

    private let naverAPI: NaverAPI

    // MARK: - Lifecycle

    init(naverAPI: NaverAPI) {
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
    public func searchOverallBooks(from sourceBook: RawBook) -> Single<[BookItem]> {
        // `Observable.just` - 초기 값 스트림 생성
        // - Note: 검색 작업을 시작하기 위한 초기 트리거를 생성할 때 사용.
        //         실제 값보다는 검색 시작을 알리는 신호로 활용.
        //         title과 author로 병렬 검색을 수행하기 위해 Observable 사용
        Observable<Void>.just(())
            // `delay` - API 호출 지연
            // - Note: 연속적인 API 호출 사이에 지연을 추가할 때 사용.
            //         서버 부하를 줄이고 안정적인 검색 수행을 위해 500ms 지연 추가.
            .delay(.milliseconds(500), scheduler: MainScheduler.instance)
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
            // `flatMap` - 추가 검색 조건 처리
            // - Note: 검색 결과가 없을 때 대체 검색을 수행할 때 사용.
            //         부제목을 제외한 메인 제목으로 재검색 수행.
            .flatMap { searchedResults -> Observable<[BookItem]> in
                let subTitleDivider = [":", "|", "-"]
                // If no results and title contains divider, try searching with main title only
                if searchedResults.isEmpty,
                   !subTitleDivider.filter({ sourceBook.title.contains($0) }).isEmpty,
                   let divider = subTitleDivider.first(where: { sourceBook.title.contains($0) }),
                   let title = sourceBook.title.split(separator: divider).first {
                    return self.naverAPI.searchBooks(query: String(title), limit: 10)
                        .asObservable()
                }

                return .just(searchedResults)
            }
            .asSingle()
    }
}
