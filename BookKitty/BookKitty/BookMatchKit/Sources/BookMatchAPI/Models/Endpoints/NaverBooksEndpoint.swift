import Foundation
import NetworkKit

struct NaverBooksEndpoint: Endpoint {
    // MARK: - Nested Types

<<<<<<< HEAD:BookKitty/BookKitty/BookMatchKit/Sources/BookMatchAPI/Models/Endpoints/NaverBooksEndpoint.swift
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
=======
    // MARK: - Internal

    typealias Response = NaverBooksResponse

    // MARK: - Properties

    let query: String
    let limit: Int
    let configuration: APIConfiguration

    // MARK: - Computed Properties

    // MARK: - Endpoint Protocol

    var baseURL: String { "https://openapi.naver.com" }

    var path: String { "/v1/search/book.json" } // baseURL에 이미 전체 경로가 포함되어 있으므로 빈 문자열
>>>>>>> develop:BookKitty/BookKitty/BookMatchKit/Sources/BookMatchAPI/Models/NaverBooksEndpoint.swift

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

<<<<<<< HEAD:BookKitty/BookKitty/BookMatchKit/Sources/BookMatchAPI/Models/Endpoints/NaverBooksEndpoint.swift
    var data: Data? { nil }

    // MARK: Private

    private let query: String
    private let limit: Int
    private let configuration: APIConfiguration
=======
    var data: Data? { nil } // GET 요청이므로 body 데이터 없음

    // MARK: - Lifecycle

    // MARK: - Initialization

    init(query: String, limit: Int, configuration: APIConfiguration) {
        self.query = query
        self.limit = limit
        self.configuration = configuration
    }
>>>>>>> develop:BookKitty/BookKitty/BookMatchKit/Sources/BookMatchAPI/Models/NaverBooksEndpoint.swift
}
