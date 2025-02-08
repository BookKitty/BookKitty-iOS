import Foundation
import Network

struct ChatGPTEndpoint: Endpoint {
    // MARK: - Lifecycle

    init(
        model: String,
        messages: [ChatMessage],
        temperature: Double,
        maxTokens: Int,
        configuration: APIConfiguration
    ) {
        self.model = model
        self.messages = messages
        self.temperature = temperature
        self.maxTokens = maxTokens
        self.configuration = configuration
    }

    // MARK: - Internal

    typealias Response = ChatGPTResponse

    // MARK: Endpoint Protocol

    var baseURL: String {
        configuration.openAIBaseURL
    }

    var path: String { "/v1/chat/completions" }

    var method: HTTPMethod { .post }

    var heaerFields: [String: String] {
        [
            "Authorization": "Bearer \(configuration.openAIApiKey)",
            "Content-Type": "application/json",
        ]
    }

    var queryItems: [URLQueryItem] { [] }

    var timeoutInterval: TimeInterval { 30.0 }

    var data: Data? {
        let requestBody: [String: Any] = [
            "model": model,
            "messages": messages.map { ["role": $0.role, "content": $0.content] },
            "temperature": temperature,
            "max_tokens": maxTokens,
        ]
        return try? JSONSerialization.data(withJSONObject: requestBody)
    }

    // MARK: - Private

    private let model: String
    private let messages: [ChatMessage]
    private let temperature: Double
    private let maxTokens: Int
    private let configuration: APIConfiguration
}
