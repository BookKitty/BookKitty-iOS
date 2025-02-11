//
//  TestConstant.swift
//  Network
//
//  Created by 권승용 on 1/28/25.
//

import Foundation
@testable import NetworkKit

enum TestConstant {
    static let url = URL(string: "https://example.com")!
    static let dummyData = TestCodableType(title: "title", body: "body")
}

struct TestCodableType: Codable, Equatable {
    let title: String
    let body: String
}

struct TestEndpoint: Endpoint {
    // MARK: - Nested Types

    typealias Response = TestCodableType

    // MARK: - Properties

    var method = Network.HTTPMethod.get

    var headerFields: [String: String] = [:]

    var timeoutInterval: TimeInterval = 30

    var baseURL = "https://example.com"

    var path = ""

    var queryItems: [URLQueryItem] = []

    var data: Data? = nil
}
