import Foundation
import NetworkKit

struct ImageDownloadEndpoint: Endpoint {
    // MARK: - Nested Types

<<<<<<< HEAD:BookKitty/BookKitty/BookMatchKit/Sources/BookMatchAPI/Models/Endpoints/ImageDownloadEndpoint.swift
    init(urlString: String) {
        self.urlString = urlString
    }
=======
    // MARK: - Internal

    typealias Response = Data
>>>>>>> develop:BookKitty/BookKitty/BookMatchKit/Sources/BookMatchAPI/Models/ImageDownloadEndpoint.swift

    // MARK: - Properties

    // MARK: - Private

    private let urlString: String

    // MARK: - Computed Properties

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

    // MARK: - Lifecycle

    // MARK: Initialization

    init(urlString: String) {
        self.urlString = urlString
    }
}
