import BookMatchCore
import Foundation
import RxSwift

/// 네이버 책 검색 API와 OpenAI API를 사용하여 도서 검색 및 추천 기능을 제공하는 클라이언트입니다.
public final class DefaultAPIClient: APIClientProtocol {
    // MARK: Lifecycle
    
    let disposeBag = DisposeBag()
    
    public init(
        configuration: APIConfiguration,
        session: URLSession = .shared
    ) {
        self.configuration = configuration
        self.session = session
    }
    
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
        
        return Single.create { [weak self] single in
            guard let self = self else {
                single(.failure(BookMatchError.invalidResponse))
                return Disposables.create()
            }
            
            guard let queryString = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                  let url = URL(string: "\(configuration.naverBaseURL)?query=\(queryString)&display=\(limit)&start=1") else {
                single(.failure(BookMatchError.networkError("Invalid URL")))
                return Disposables.create()
            }
            
            var request = URLRequest(url: url)
            request.setValue(configuration.naverClientId, forHTTPHeaderField: "X-Naver-Client-Id")
            request.setValue(configuration.naverClientSecret, forHTTPHeaderField: "X-Naver-Client-Secret")
            
            let task = session.dataTask(with: request) { data, response, error in
                if let error = error {
                    single(.failure(error))
                    return
                }
                
                guard let data = data else {
                    single(.failure(BookMatchError.invalidResponse))
                    return
                }
                
                do {
                    let naverResponse = try JSONDecoder().decode(NaverBooksResponse.self, from: data)
                    single(.success(naverResponse.items.map { $0.toBookItem() }))
                } catch {
                    single(.failure(error))
                }
            }
            
            /// URLSession 데이터 태스크를 실제로 시작
            task.resume()
            
            /// RxSwift의 구독이 해제(dispose)될 때 실행될 정리(cleanup) 코드를 정의
            ///
            /// dispose() 직접 실행하거나, 화면에 dismiss됨으로서, disposeBag이 메모리 해제될 때, task.cancel이 호출됨
            ///
            /// 아래 상황에서 task.cancel()이 호출됨
            /// - 사용자가 화면을 벗어날 때
            /// - 새로운 요청이 시작될 때
            /// - 구독이 명시적으로 해제될 때disposeBag이 해제될 때
            return Disposables.create {
                task.cancel()
            }
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
    ) -> Single<GPTRecommendationForQuestion> {
        let messages = [
            ChatMessage(role: "system", content: Prompts.recommendationForQuestion),
            ChatMessage(
                role: "user",
                content: "질문: \(question)\n보유도서: \(ownedBooks.map { "\($0.title)-\($0.author)" })"
            ),
        ]
        
        let maxRetries = 3
        var retryCount = 0
        
        return Single.create { [weak self] single in
            guard let self = self else {
                single(.failure(BookMatchError.invalidResponse))
                return Disposables.create()
            }
            
            
            while retryCount < maxRetries {
                do {
                    let response = try sendChatRequest(
                        messages: messages,
                        temperature: 0.01,
                        maxTokens: 500
                    )
                    
                    guard let jsonString = response.choices.first?.message.content,
                          let jsonData = jsonString.data(using: .utf8) else {
                        single(.failure(BookMatchError.invalidResponse))
                        return Disposables.create()
                    }
                    
                    let result = try JSONDecoder().decode(GPTRecommendationForQuestionDTO.self,from: jsonData)
                    
                    single(.success(result.toDomain(ownedBooks)))
                } catch {
                    retryCount += 1
                    print("Retry attempt in getBookRecommendation \(retryCount): \(error)")
                }
            }
            
            /// 3회 재시도하여도 sendChatRequest로부터 에러를 계속 반환받거나, GPT로부터 반환받은 결과가 형식에 맞지 않을 경우 invalidResponse를 반환합니다.
            single(.failure(BookMatchError.invalidResponse))
        }
    }
    
    /// `ChatGPT api`를 활용, `보유도서 기반 추천 도서`를 요청 및 반환받습니다.
    ///
    ///  - Parameters:
    ///     - ownedBooks: 사용자 보유 도서 배열
    ///  - Returns: ``Rawbook`` 타입의 추천도서 배열
    ///  - Throws: GPT 반환 형식 에러
    public func getBookRecommendation(ownedBooks: [OwnedBook])
    ->  Single<GPTRecommendationFromOwnedBooks> {
        let messages = [
            ChatMessage(role: "system", content: Prompts.recommendationFromOwnedBooks),
            ChatMessage(
                role: "user",
                content: "보유도서 제목-저자 목록: \(ownedBooks.map { "\($0.title)-\($0.author)" })"
            ),
        ]
        
        let maxRetries = 3
        var retryCount = 0
        
        return Single.create { [weak self] single in
            guard let self = self else {
                single(.failure(BookMatchError.invalidResponse))
                return Disposables.create()
            }
            
            while retryCount < maxRetries {
                do {
                    let response = try sendChatRequest(
                        messages: messages,
                        temperature: 0.01,
                        maxTokens: 500
                    )
                    
                    guard let jsonString = response.choices.first?.message.content,
                          let jsonData = jsonString.data(using: .utf8) else {
                        single(.failure(BookMatchError.invalidResponse))
                        return Disposables.create()
                    }
                    
                    let result = try JSONDecoder().decode(GPTRecommendationFromOwnedBooksDTO.self,from: jsonData)
                    
                    single(.success(result.toDomain()))
                } catch {
                    retryCount += 1
                    print("Retry attempt in getBookRecommendation \(retryCount): \(error)")
                }
            }
            
            // 3회 재시도하여도 sendChatRequest로부터 에러를 계속 반환받거나, GPT로부터 반환받은 결과가 형식에 맞지 않을 경우 invalidResponse를
            // 반환합니다.
            single(.failure(BookMatchError.invalidResponse))
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
        
        let maxRetries = 3
        var retryCount = 0
        
        return Single.create { [weak self] single in
            guard let self = self else {
                single(.failure(BookMatchError.invalidResponse))
                return Disposables.create()
            }
            
            while retryCount < maxRetries {
                do {
                    let response = try sendChatRequest(
                        messages: messages,
                        temperature: 0.01,
                        maxTokens: 100
                    )
                    
                    guard let result = response.choices.first?.message.content,
                          result.map({ String($0) }).contains("-") else {
                        single(.failure(BookMatchError.invalidResponse))
                        return Disposables.create()
                    }
                    
                    let arr = result
                        .split(separator: "-")
                        .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
                    
                    single(.success(RawBook(title: arr[0], author: arr[1])))
                } catch {
                    retryCount += 1
                    print("Retry attempt in getAdditionalBook \(retryCount): \(error)")
                }
            }
            
            // 3회 재시도하여도 sendChatRequest로부터 에러를 계속 반환받거나, GPT로부터 반환받은 결과가 형식에 맞지 않을 경우 invalidResponse를
            // 반환합니다.
            single(.failure(BookMatchError.invalidResponse))
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
        
        let maxRetries = 3
        var retryCount = 0
        
        return Single.create { [weak self] single in
            guard let self = self else {
                single(.failure(BookMatchError.invalidResponse))
                return Disposables.create()
            }
            
            while retryCount < maxRetries {
                sendChatRequest(
                    model: "gpt-4o-mini",
                    messages: messages,
                    temperature: 1.0,
                    maxTokens: 500
                )
                .subscribe(onSuccess: {response in
                    if let result = response.choices.first?.message.content {
                        single(.success(result))
                    }
                }, onFailure: { error in
                    retryCount += 1
                    print("Retry attempt in getDescription \(retryCount)")
                })
                .disposed(by: disposeBag)
            }
            
            // 3회 재시도하여도 sendChatRequest로부터 에러를 계속 반환받거나, GPT로부터 반환받은 결과가 형식에 맞지 않을 경우 invalidResponse를
            // 반환합니다.
            single(.failure(BookMatchError.invalidResponse))
        }
    }
    
    // MARK: Private
    
    private let configuration: APIConfiguration
    private let session: URLSession
    
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
        
        return Single.create { [weak self] single in
            guard let self = self else {
                single(.failure(BookMatchError.invalidResponse))
                return Disposables.create()
            }
            
            guard let url = URL(string: configuration.openAIBaseURL) else {
                single(.failure(BookMatchError.networkError("Invalid URL")))
                return Disposables.create()
            }
            
            let requestBody: [String: Any] = [
                "model": model,
                "messages": messages.map { ["role": $0.role, "content": $0.content] },
                "temperature": temperature,
                "max_tokens": maxTokens,
            ]
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue(
                "Bearer \(configuration.openAIApiKey)",
                forHTTPHeaderField: "Authorization"
            )
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            } catch {
                single(.failure(error))
                return Disposables.create()
            }
            
            let task = session.dataTask(with: request) { data,reponse,error in
                if let error = error {
                    single(.failure(error))
                    return
                }
                
                guard let data = data else {
                    single(.failure(BookMatchError.invalidResponse))
                    return
                }
                
                do {
                    let response = try JSONDecoder().decode(ChatGPTResponse.self, from: data)
                    single(.success(response))
                } catch {
                    single(.failure(error))
                }
            }
            
            task.resume()
            
            return Disposables.create {
                task.cancel()
            }
        }
    }
}
