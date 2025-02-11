import Foundation
import NetworkKit

struct ImageDownloadEndpoint: Endpoint {
    // MARK: - Nested Types

    typealias Response = Data

    // MARK: - Properties

    var path = ""

    var method = HTTPMethod.get

    // MARK: - Private

    private let urlString: String

    // MARK: - Computed Properties

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

    // MARK: - Lifecycle

    init(urlString: String) {
        self.urlString = urlString
    }
}
