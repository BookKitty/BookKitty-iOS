import Foundation
import NetworkKit

struct NaverBooksEndpoint: Endpoint {
    // MARK: - Nested Types

    init(query: String, limit: Int, configuration: APIConfiguration) {
        self.query = query
        self.limit = limit
        self.configuration = configuration
    }

    // MARK: Internal

    typealias Response = NaverBooksResponse

    var baseURL = "https://openapi.naver.com"
    var path = "/v1/search/book.json"
    var method = HTTPMethod.get

    var headerFields: [String: String] {
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

    var data: Data? { nil }

    // MARK: Private

    private let query: String
    private let limit: Int
    private let configuration: APIConfiguration
}
