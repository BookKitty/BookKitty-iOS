import BookMatchCore

/// OpenAI API로부터 받은 응답을 디코딩하기 위한 구조체입니다.
struct ChatGPTResponse: Decodable {
    // MARK: - Nested Types

    struct Choice: Decodable {
        // MARK: - Nested Types

        struct Message: Decodable {
            let content: String
        }

        // MARK: - Properties

        let message: Message
    }

    // MARK: - Properties

    let choices: [Choice]
}

struct ChatMessage: Decodable {
    let role: String
    let content: String
}
