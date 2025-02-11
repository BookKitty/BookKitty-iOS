import BookMatchCore
import Foundation
import NetworkKit
import RxSwift
import UIKit

/// 네이버 책 검색 API와 OpenAI API를 사용하여 도서 검색 및 추천 기능을 제공하는 클라이언트입니다.
public final class DefaultAPIClient: APIClientProtocol {
    // MARK: - Properties

    // MARK: Private

    private let configuration: APIConfiguration
    private let disposeBag = DisposeBag()

    // MARK: - Lifecycle

    public init(
        configuration: APIConfiguration
    ) {
        self.configuration = configuration
    }

    // MARK: - Functions

    // MARK: Public

    /// `네이버 책검색 api`를 활용, 도서를 검색합니다.
    ///
    ///  - Parameters:
    ///     - query: 검색어
    ///     - limit: 검색 결과 제한 수 (기본값: 10)
    ///  - Returns: 검색된 도서 목록
    ///  - Throws: 단순 네트워크 에러
    public func searchBooks(query: String, limit: Int = 10) -> Single<[BookItem]> {
        guard !query.isEmpty else {
            return .just([])
        }

        let endpoint = NaverBooksEndpoint(
            query: query,
            limit: limit,
            configuration: configuration
        )

        return NetworkManager.shared.request(endpoint)
            .map { response -> [BookItem] in
                guard let response else {
                    throw BookMatchError.invalidResponse
                }

                return response.items.map { $0.toBookItem() }
            }
            .catch { error in
                if let networkError = error as? NetworkError {
                    return .error(
                        BookMatchError.networkError(networkError.localizedDescription)
                    )
                }

                return .error(error)
            }
    }

    /// URL로부터 이미지를 다운로드합니다.
    ///
    /// - Parameters:
    ///   - urlString: 이미지 URL 문자열
    /// - Returns: 다운로드된 UIImage
    /// - Throws: BookMatchError.networkError
    public func downloadImage(from urlString: String) -> Single<UIImage> {
        let endpoint = ImageDownloadEndpoint(urlString: urlString)

        return NetworkManager.shared.request(endpoint)
            .map { data -> UIImage in
                guard let data,
                      let image = UIImage(data: data) else {
                    throw BookMatchError.networkError("Image Fetch Failed")
                }
                return image
            }
            .catch { error in
                if let networkError = error as? NetworkError {
                    switch networkError {
                    case .invalidURL:
                        return .error(BookMatchError.networkError("Invalid URL"))
                    case .decodingFailed:
                        return .error(BookMatchError.networkError("Image Fetch Failed"))
                    default:
                        return .error(
                            BookMatchError
                                .networkError(networkError.localizedDescription)
                        )
                    }
                }
                return .error(error)
            }
    }

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
                throw BookMatchError.invalidResponse
            }
            return result
        }
        .retry(3)
        .catch { _ in
            // 3회 재시도 후에도 실패하면 invalidResponse를 반환
            throw BookMatchError.invalidResponse
        }
    }

    /// `ChatGPT api`를 활용, `질문 기반 추천 도서`를 요청 및 반환받습니다.
    ///
    ///  - Parameters:
    ///     - question: 사용자 질문
    ///     - ownedBooks: 사용자 보유 도서 배열
    ///  - Returns: 보유/미보유에 대해 각각 도서 추천
    ///  - Throws: GPT 반환 형식 에러
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
                      AiRecommendationForQuestionDTO.self,
                      from: jsonData
                  ) else {
                throw BookMatchError.invalidResponse
            }

            return result.toDomain(ownedBooks)
        }
        .retry(3)
        .catch { _ in
            throw BookMatchError.invalidResponse
        }
    }

    /// `ChatGPT api`를 활용, `보유도서 기반 추천 도서`를 요청 및 반환받습니다.
    ///
    ///  - Parameters:
    ///     - ownedBooks: 사용자 보유 도서 배열
    ///  - Returns: ``Rawbook`` 타입의 추천도서 배열
    ///  - Throws: GPT 반환 형식 에러
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
                  let result = try? JSONDecoder().decode(
                      AiRecommendationFromOwnedBooksDTO.self,
                      from: jsonData
                  )
            else {
                throw BookMatchError.invalidResponse
            }

            return result.toDomain()
        }
        .retry(3)
        .catch { _ in
            // 3회 재시도 후에도 실패하면 invalidResponse를 반환
            throw BookMatchError.invalidResponse
        }
    }

    /// `ChatGPT api`를 활용, `질문 기반 추천 도중, 새로운 추천도서`를 `재요청` 및 반환받습니다.
    ///
    ///  - Parameters:
    ///     - question: 사용자 질문
    ///     - previousBooks: 기존에 GPT가 이미 추천했던 도서 배열
    ///  - Returns: ``Rawbook`` 타입의 단일 추천도서
    ///  - Throws: GPT 반환 형식 에러
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
                throw BookMatchError.invalidResponse
            }

            let arr = result
                .split(separator: "-")
                .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }

            return RawBook(title: arr[0], author: arr[1])
        }
        .retry(3)
        .catch { _ in
            // 3회 재시도 후에도 실패하면 invalidResponse를 반환
            throw BookMatchError.invalidResponse
        }
    }

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
                    throw BookMatchError.invalidResponse
                }
                return response
            }
            .catch { error in
                if let networkError = error as? NetworkError {
                    switch networkError {
                    case .invalidURL:
                        return .error(BookMatchError.networkError("Invalid URL"))
                    case .decodingFailed:
                        return .error(BookMatchError.invalidResponse)
                    default:
                        return .error(
                            BookMatchError
                                .networkError(networkError.localizedDescription)
                        )
                    }
                }
                return .error(error)
            }
    }
}
