import BookMatchCore
import Foundation
import NetworkKit
import RxSwift

public final class OpenAIAPI: BaseAPIClient, AIRecommendable {
    // MARK: - Lifecycle

    override public init(configuration: APIConfiguration) {
        super.init(configuration: configuration)
    }

    // MARK: - Functions

    /// `ChatGPT api`를 활용, `질문 기반 추천 도중, 도서 추천 이유`를 요청 및 반환받습니다.
    ///
    ///  - Parameters:
    ///     - question: 사용자 질문
    ///     - books: 이전 GPT가 추천한 도서 배열
    ///  - Returns: 추천 이유 글
    ///  - Throws: GPT 반환 형식 에러
    public func getDescription(
        question: String,
        books: [RawBook]
    ) -> Single<String> {
        let messages = [
            ChatMessage(role: "system", content: Prompts.description),
            ChatMessage(
                role: "user",
                content: "질문: \(question)\n해당 질문에 대해 선정된 도서 목록: \(books.map { "\($0.title)-\($0.author)" }.joined(separator: ","))"
            ),
        ]

        return sendChatRequest(
            model: "gpt-4o-mini",
            messages: messages,
            temperature: 1.0,
            maxTokens: 500
        )
        .map { response -> String in
            guard let result = response.choices.first?.message.content else {
                throw BookMatchError.invalidGPTFormat
            }
            return result
        }
        .retry(3)
    }

    /// `ChatGPT api`를 활용, `질문 기반 추천 도서`를 요청 및 반환받습니다.
    ///
    ///  - Parameters:
    ///     - question: 사용자 질문
    ///     - ownedBooks: 사용자 보유 도서 배열
    ///  - Returns: 보유/미보유에 대해 각각 도서 추천
    ///  - Throws: ``invalidGPTFormat``, ``networkError``
    public func getBookRecommendation(
        question: String,
        ownedBooks: [OwnedBook]
    ) -> Single<AiRecommendationForQuestion> {
        let messages = [
            ChatMessage(role: "system", content: Prompts.recommendationForQuestion),
            ChatMessage(
                role: "user",
                content: "질문: \(question)\n보유도서: \(ownedBooks.map { "\($0.title)-\($0.author)" })"
            ),
        ]

        return sendChatRequest(
            messages: messages,
            temperature: 0.01,
            maxTokens: 100
        )
        .map { response in
            guard let jsonString = response.choices.first?.message.content,
                  let jsonData = jsonString.data(using: .utf8),
                  let result = try? JSONDecoder().decode(
                      RecommendationOwnedNewDTO.self,
                      from: jsonData
                  ) else {
                throw BookMatchError.invalidGPTFormat
            }

            return result.toDomain(ownedBooks)
        }
        .retry(3)
        .catch { _ in
            throw BookMatchError.invalidGPTFormat
        }
    }

    /// `ChatGPT api`를 활용, `보유도서 기반 추천 도서`를 요청 및 반환받습니다.
    ///
    ///  - Parameters:
    ///     - ownedBooks: 사용자 보유 도서 배열
    ///  - Returns: ``Rawbook`` 타입의 추천도서 배열
    ///  - Throws: ``invalidGPTFormat``, ``networkError``
    public func getBookRecommendation(ownedBooks: [OwnedBook])
        -> Single<AiRecommendationFromOwnedBooks> {
        let messages = [
            ChatMessage(role: "system", content: Prompts.recommendationFromOwnedBooks),
            ChatMessage(
                role: "user",
                content: "보유도서 제목-저자 목록: \(ownedBooks.map { "\($0.title)-\($0.author)" })"
            ),
        ]

        return sendChatRequest(
            messages: messages,
            temperature: 0.01,
            maxTokens: 500
        )
        .map { response in
            guard let jsonString = response.choices.first?.message.content,
                  let jsonData = jsonString.data(using: .utf8),
                  let result = try? JSONDecoder().decode(RecommendationsDTO.self, from: jsonData)
            else {
                throw BookMatchError.invalidGPTFormat
            }

            return result.toDomain()
        }
        .retry(3)
    }

    /// `ChatGPT api`를 활용, `질문 기반 추천 도중, 새로운 추천도서`를 `재요청` 및 반환받습니다.
    ///
    ///  - Parameters:
    ///     - question: 사용자 질문
    ///     - previousBooks: 기존에 GPT가 이미 추천했던 도서 배열
    ///  - Returns: ``Rawbook`` 타입의 단일 추천도서
    ///  - Throws: ``invalidGPTFormat``, ``networkError``
    public func getAdditionalBook(
        question: String,
        previousBooks: [RawBook]
    ) -> Single<RawBook> {
        let messages = [
            ChatMessage(role: "system", content: Prompts.additionalBook),
            ChatMessage(
                role: "user",
                content: "질문: \(question)\n기존 도서 제목 배열: \(previousBooks.map(\.title))"
            ),
        ]

        return sendChatRequest(
            messages: messages,
            temperature: 0.01,
            maxTokens: 100
        )
        .map { response in
            guard let result = response.choices.first?.message.content else {
                throw BookMatchError.invalidGPTFormat
            }

            let arr = result
                .split(separator: "-")
                .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }

            return RawBook(title: arr[0], author: arr[1])
        }
        .retry(3)
    }
}

extension OpenAIAPI {
    /// `ChatGPT api`를 요청합니다. APIClient의 public 메서드들이 모두 이 메서드를 공용합니다.
    ///
    ///  - Parameters:
    ///     - model: 사용자 질문
    ///     - messages: 이전 GPT가 추천한 도서 배열
    ///     - temperature:GPT의 인간미?
    ///     - maxTokens:반환받는 답변에 대한 토큰 상한선
    ///  - Returns: GPT 반환 타입
    private func sendChatRequest(
        model: String = "gpt-4o",
        messages: [ChatMessage],
        temperature: Double,
        maxTokens: Int
    ) -> Single<ChatGPTResponse> {
        let endpoint = ChatGPTEndpoint(
            model: model,
            messages: messages,
            temperature: temperature,
            maxTokens: maxTokens,
            configuration: configuration
        )

        return NetworkManager.shared.request(endpoint)
            .map { response in
                guard let response else {
                    throw BookMatchError.networkError
                }
                return response
            }
    }
}
