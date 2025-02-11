import BookMatchCore

/// OpenAI API로부터 받은 응답을 디코딩하기 위한 구조체입니다.
struct ChatGPTResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            let content: String
        }

        let message: Message
    }

    let choices: [Choice]
}

struct ChatMessage: Codable {
    let role: String
    let content: String
}
