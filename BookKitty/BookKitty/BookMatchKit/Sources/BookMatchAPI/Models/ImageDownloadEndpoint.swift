import Foundation
import Network

struct ImageDownloadEndpoint: Endpoint {
    // MARK: Lifecycle

    // MARK: Initialization

    init(urlString: String) {
        self.urlString = urlString
    }

    // MARK: Internal

    typealias Response = Data

    // MARK: Endpoint Protocol

    var baseURL: String {
        urlString
    }

    var path: String { "" }

    var method: HTTPMethod { .get }

    var heaerFields: [String: String] { [:] }

    var queryItems: [URLQueryItem] { [] }

    var timeoutInterval: TimeInterval { 30.0 }

    var data: Data? { nil }

    // MARK: Private

    private let urlString: String
}
