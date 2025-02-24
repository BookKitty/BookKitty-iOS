import BookMatchCore
import NetworkKit
import RxSwift

public final class NaverAPI: BaseAPIClient, _BookSearchable {
    // MARK: - Lifecycle

    /// BaseAPIClient의 configuration 속성이 internal 이상의 접근 수준을 가지고 있기에,
    /// configuration은 자동으로 하위 클래스에 상속되어 사용 가능
    override public init(configuration: APIConfiguration) {
        super.init(configuration: configuration)
    }

    // MARK: - Functions

    /// `네이버 책검색 api`를 활용, 도서를 검색합니다.
    ///
    ///  - Parameters:
    ///     - query: 검색어
    ///     - limit: 검색 결과 제한 수 (기본값: 10)
    ///  - Returns: 검색된 도서 목록
    ///  - Throws: 단순 네트워크 에러
    public func searchBooks(query: String, limit: Int = 10) -> Single<[BookItem]> {
        guard !query.isEmpty else {
            return .just([])
        }

        let endpoint = NaverBooksEndpoint(
            query: query,
            limit: limit,
            configuration: configuration
        )

        return NetworkManager.shared.request(endpoint)
            .map { response -> [BookItem] in
                guard let response else {
                    throw BookMatchError.networkError
                }

                return response.items.map { $0.toBookItem() }
            }
    }
}
