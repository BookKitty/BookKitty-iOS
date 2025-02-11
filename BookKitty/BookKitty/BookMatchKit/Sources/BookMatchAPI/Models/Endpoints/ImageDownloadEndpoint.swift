import Foundation
import Network

struct ImageDownloadEndpoint: Endpoint {
    // MARK: Lifecycle

    init(urlString: String) {
        self.urlString = urlString
    }

    // MARK: Internal

    typealias Response = Data

    var path = ""

    var method = HTTPMethod.get

    // MARK: Endpoint Protocol

    /// Cannot use instance member 'urlString' within property initializer; property initializers
    /// run before 'self' is available
    var baseURL: String {
        urlString
    }

    var headerFields: [String: String] { [:] }

    var queryItems: [URLQueryItem] { [] }

    var timeoutInterval: TimeInterval { 30.0 }

    var data: Data? { nil }

    // MARK: Private

    private let urlString: String
}
