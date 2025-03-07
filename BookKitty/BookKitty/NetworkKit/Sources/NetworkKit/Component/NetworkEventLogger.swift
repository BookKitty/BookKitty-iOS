//
//  NetworkEventLogger.swift
//  NetworkKit
//
//  Created by 권승용 on 2/14/25.
//

import Foundation
import OSLog

enum NetworkEventLogger {
    // MARK: - Static Properties

    // MARK: - Private

    // 로깅에 사용되는 Logger 인스턴스

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.BookshelfML.BookKitty",
        category: "Network"
    )

    // MARK: - Static Functions

    // MARK: - Internal

    /// 네트워크 요청이 완료되었을 때 호출되어 요청 정보를 로깅합니다.
    /// - Parameter request: 로깅할 URL 요청 객체
    static func requestDidFinish(_ request: URLRequest) {
        logger.debug(
            """
            ------------------------------------------------------- 
            🤙 API 호출 완료 / URL: \(request.url?.absoluteString ?? "")
            ------------------------------------------------------- 
            """
        )
    }

    /// 네트워크 응답을 받았을 때 호출되어 응답 정보를 로깅합니다.
    /// - Parameters:
    ///   - data: 응답으로 받은 데이터
    ///   - response: HTTP 응답 객체
    static func responseDidFinish(_ data: Data?, _ response: HTTPURLResponse) {
        logger.debug(
            """
            -------------------------------------------------------
            🛰️ API 응답 완료 / StatusCode: \(response.statusCode)
            -------------------------------------------------------
            Body: \(data?.toPrettyString() ?? "Empty")
            -------------------------------------------------------
            """
        )
    }
}

extension Data {
    /// Data 객체를 보기 좋은 JSON 문자열로 변환합니다.
    /// - Returns: 들여쓰기가 적용된 JSON 문자열. 변환 실패 시 빈 문자열 반환
    func toPrettyString() -> String {
        if
            let jsonObject = try? JSONSerialization.jsonObject(with: self, options: []),
            let prettyJsonData = try? JSONSerialization.data(
                withJSONObject: jsonObject,
                options: .prettyPrinted
            ),
            let prettyPrintedString = String(data: prettyJsonData, encoding: .utf8) {
            return prettyPrintedString
        }

        return String(data: self, encoding: .utf8) ?? ""
    }
}
