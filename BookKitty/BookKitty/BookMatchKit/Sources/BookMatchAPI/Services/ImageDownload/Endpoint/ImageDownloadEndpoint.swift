import Foundation
import NetworkKit

struct ImageDownloadEndpoint: Endpoint {
    // MARK: - Nested Types

    typealias Response = Data

    // MARK: - Properties


    var method = HTTPMethod.get

    // MARK: - Private

    private let urlString: String

    // MARK: - Computed Properties

    // MARK: Endpoint Protocol

    /// Cannot use instance member 'urlString' within property initializer; property initializers
    /// run before 'self' is available
    
    var baseURL: String {
        // URL에서 scheme과 host만 추출
        guard let url = URL(string: urlString),
              let scheme = url.scheme,
              let host = url.host else {
            return urlString
        }
        return "\(scheme)://\(host)"
    }
       
    var path: String {
        guard let url = URL(string: urlString) else { return "" }
        var pathWithQuery = url.path
        if let query = url.query {
            pathWithQuery += "?\(query)"
        }
        return pathWithQuery
    }

    var headerFields: [String: String] { [:] }

    var queryItems: [URLQueryItem] { [] }

    var timeoutInterval: TimeInterval { 30.0 }

    var data: Data? { nil }

    // MARK: - Lifecycle

    init(urlString: String) {
        self.urlString = urlString
    }
}
