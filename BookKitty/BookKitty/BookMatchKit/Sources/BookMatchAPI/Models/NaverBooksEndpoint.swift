import Foundation
import Network

struct NaverBooksEndpoint: Endpoint {
    // MARK: - Lifecycle

    // MARK: - Initialization

    init(query: String, limit: Int, configuration: APIConfiguration) {
        self.query = query
        self.limit = limit
        self.configuration = configuration
    }

    // MARK: - Internal

    typealias Response = NaverBooksResponse

    let query: String
    let limit: Int
    let configuration: APIConfiguration

    // MARK: - Endpoint Protocol

    var baseURL: String { "https://openapi.naver.com" }

    var path: String { "/v1/search/book.json" } // baseURL에 이미 전체 경로가 포함되어 있으므로 빈 문자열

    var method: HTTPMethod { .get }

    var heaerFields: [String: String] {
        [
            "X-Naver-Client-Id": configuration.naverClientId,
            "X-Naver-Client-Secret": configuration.naverClientSecret,
        ]
    }

    var queryItems: [URLQueryItem] {
        [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "display", value: String(limit)),
            URLQueryItem(name: "start", value: "1"),
        ]
    }

    var timeoutInterval: TimeInterval { 30.0 } // 기본 30초 타임아웃

    var data: Data? { nil } // GET 요청이므로 body 데이터 없음
}
