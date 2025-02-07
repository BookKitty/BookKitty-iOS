//
//  Environment.swift
//  BookKitty
//
//  Created by 권승용 on 2/7/25.
//

import Foundation

struct Environment {
    // MARK: Internal

    var naverClientID: String {
        getEnvironmentVariable("NAVER_CLIENT_ID")
    }

    var naverClientSecret: String {
        getEnvironmentVariable("NAVER_CLIENT_SECRET")
    }

    var naverBundleID: String {
        getEnvironmentVariable("NAVER_BUNDLE_ID")
    }

    var openaiAPIKey: String {
        getEnvironmentVariable("OPENAI_API_KEY")
    }

    // MARK: Private

    private func getEnvironmentVariable(_ name: String) -> String {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: name) as? String else {
            fatalError("no api key found")
        }
        return apiKey
    }
}
