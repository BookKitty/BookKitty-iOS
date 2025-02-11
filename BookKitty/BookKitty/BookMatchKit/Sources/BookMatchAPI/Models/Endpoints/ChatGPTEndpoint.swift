import Foundation
import NetworkKit

struct ChatGPTEndpoint: Endpoint {
    // MARK: - Nested Types

    // MARK: - Internal

    typealias Response = ChatGPTResponse

    var baseURL = "https://api.openai.com"
    var path = "/v1/chat/completions"
    var method = HTTPMethod.post

    var headerFields: [String: String] {
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
}
