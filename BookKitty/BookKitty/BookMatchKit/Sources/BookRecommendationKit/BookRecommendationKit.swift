import BookMatchAPI
import BookMatchCore
import BookMatchService
import CoreFoundation
import RxSwift
import UIKit

@_exported import enum BookMatchCore.BookMatchError
@_exported import struct BookMatchCore.OwnedBook

/// 도서 매칭 및 추천 기능의 핵심 모듈입니다.
/// 사용자의 요청을 처리하고, 도서 검색, 매칭, 추천 기능을 조율합니다.
public final class BookRecommendationKit: BookRecommendable {
    // MARK: - Properties

    private let openAiAPI: OpenAIAPI
    private let serviceFactory: ServiceFactory
    private let validationService: BookValidatable

    // MARK: - Lifecycle

    public init(
        naverClientId: String,
        naverClientSecret: String,
        openAIApiKey: String,
        similiarityThreshold: [Double] = [0.4, 0.8],
        maxRetries: Int = 3,
        titleWeight: Double = 0.8
    ) {
        serviceFactory = ServiceFactory(
            naverClientId: naverClientId,
            naverClientSecret: naverClientSecret,
            openAIApiKey: openAIApiKey,
            similarityThreshold: similiarityThreshold,
            maxRetries: maxRetries,
            titleWeight: titleWeight
        )

        validationService = serviceFactory.makeBookValidationService()
        openAiAPI = serviceFactory.makeOpenAIAPI()
    }

    // MARK: - Functions

    // MARK: Public

    /// `보유 도서 목록`을 기반으로 새로운 도서를 `추천`합니다.
    ///
    /// - Parameters:
    ///   - ownedBooks: 사용자가 보유한 도서 목록
    /// - Returns: 추천된 도서 목록
    public func recommendBooks(from ownedBooks: [OwnedBook]) -> Single<[BookItem]> {
        BookMatchLogger.recommendationStarted(question: nil)

        return openAiAPI.getBookRecommendation(ownedBooks: ownedBooks)
            // `flatMap` - GPT 추천 결과를 `실제 도서로 변환`
            // - Note: GPT가 추천한 도서 목록을 실제 존재하는 도서로 매칭할 때 사용.
            //         각 추천 도서에 대해 실제 도서 검색을 수행하고 결과를 새로운 스트림으로 변환.
            //         메모리 해제 검사도 함께 수행.
            .flatMap { [weak self] result -> Single<[BookItem]> in
                guard let self else {
                    return .just([])
                }

                // `Observable.from` - 배열을 개별 요소로 분리
                // - Note: 추천된 도서 배열의 각 도서를 개별적으로 처리하기 위해 사용.
                //         각 도서에 대해 독립적인 매칭 작업을 수행할 수 있게 함.
                return Observable.from(result.books)
                    // `flatMap` - 개별 도서를 실제 도서로 매칭
                    // - Note: 각 추천 도서를 실제 도서 정보로 변환할 때 사용.
                    //         matchToRealBook 메서드를 통해 각 도서를 실제 존재하는 도서와 매칭.
                    .flatMap { book -> Single<BookItem?> in
                        self.validationService.validateRecommendedBook(book)
                            .map { result -> BookItem? in
                                if let matchedBook = result.book {
                                    return matchedBook
                                }
                                return nil
                            }
                    }
                    // `compactMap` - nil 값 제거
                    //
                    // ```
                    // // filter + map할 경우 강제 언레핑이 필요하게 됨.
                    // .filter { $0 != nil }  /// nil 체크
                    // .map { $0! }          /// 강제 언래핑 필요
                    // ```
                    //
                    // - Note: 매칭에 실패한 도서(nil)를 결과에서 제외할 때 사용.
                    //         성공적으로 매칭된 도서만 최종 결과에 포함.
                    .compactMap { $0 }
                    // `toArray` - 개별 결과를 배열로 변환
                    // - Note: 개별적으로 처리된 도서들을 `하나의 배열로 모을 때` 사용.
                    //         최종적으로 추천 도서 목록을 생성.
                    .toArray()
                    // `map` - 중복 제거
                    // - Note: 최종 결과에서 중복된 도서를 제거할 때 사용.
                    //         Set을 통해 중복을 제거하고 다시 배열로 변환.
                    .map { Array(Set($0)) }
                    .catch { _ in
                        .just([])
                    }
            }
    }

    /// 사용자의 `질문`과 보유 도서를 기반으로 도서를 `추천`합니다.
    ///
    /// - Parameters:
    ///   - input: 사용자의 질문과 보유 도서 정보를 포함한 입력 데이터
    /// - Returns: 추천된 도서 목록과 설명을 포함한 출력 데이터
    /// - Throws: BookMatchError.questionShort (질문이 4글자 미만인 경우)
    public func recommendBooks(for question: String, from ownedBooks: [OwnedBook])
        -> Single<BookMatchModuleOutput> {
        BookMatchLogger.recommendationStarted(question: question)

        return openAiAPI.getBookRecommendation(question: question, ownedBooks: ownedBooks)
            // `do` - 사이드 이펙트 처리하며 스트림을 계속 진행해야하는 상황이므로 선택, Subscribe는 체이닝이 종료되는 시점에 사용
            // - Note: 스트림을 변경하지 않고 로깅을 수행할 때 사용.
            //         추천 결과를 로그로 기록하면서 원본 데이터는 그대로 유지.
            .do(onSuccess: { result in
                let resultString = """
                보유 도서 기반 추천 목록: \(result.ownedBooks.map(\.title))
                미보유 도서 기반 추천 목록: \(result.newBooks.map(\.title))
                """

                BookMatchLogger.gptResponseReceived(result: resultString)
            })
            // `flatMap` - 추천 결과를 실제 도서로 변환
            // - Note: GPT 추천 결과를 실제 도서 정보로 변환할 때 사용.
            //         추천된 도서들을 비동기적으로 실제 도서와 매칭하고 새로운 스트림 생성.
            .flatMap { [weak self] recommendation -> Single<(
                recommendation: RecommendationForQuestion,
                books: [BookItem]
            )> in
                guard let self else {
                    BookMatchLogger.error(
                        BookMatchError.deinitError,
                        context: "추천 절차"
                    )

                    return .error(BookMatchError.deinitError)
                }

                var previousBooks = recommendation.newBooks

                // `Observable.from` - 배열을 개별 요소로 분리
                // - Note: 새로 추천된 도서들을 개별적으로 처리하기 위해 사용.
                //         각 도서에 대해 순차적인 매칭 작업 수행.
                return Observable.from(recommendation.newBooks)
                    // `concatMap` - 순차적 매칭 수행
                    // - Note: 각 도서를 순서대로 매칭할 때 사용.
                    //         이전 매칭 작업이 완료된 후 다음 매칭을 시작하여 순서 보장.
                    //         ``matchToRealBook()`` -> previousBooks 갱신 -> ``matchToRealBook()`` ->
                    // previousBooks 갱신...
                    .concatMap { book -> Observable<BookItem?> in
                        self.validationService.findMatchingBookWithRetry(
                            book: book,
                            question: question,
                            previousBooks: previousBooks,
                            openAiAPI: self.openAiAPI
                        )
                        .asObservable()
                        // `do` - 매칭 완료 후 처리
                        // - Note: 매칭이 완료된 도서를 이전 도서 목록에 추가할 때 사용.
                        //         다음 매칭 작업을 위한 컨텍스트 업데이트.
                        .do(onNext: { _ in
                            previousBooks.append(book)
                        })
                    }
                    // `compactMap` - nil 값 제거
                    // - Note: 매칭에 실패한 도서를 결과에서 제외할 때 사용.
                    //         성공적으로 매칭된 도서만 최종 결과에 포함.
                    .compactMap { $0 }
                    // `toArray` - 개별 결과를 배열로 변환
                    // - Note: 매칭된 도서들을 하나의 배열로 모을 때 사용.
                    //         최종 추천 도서 목록 생성.
                    .toArray()
                    // `map` - 최종 결과 구조화
                    // - Note: 원본 추천 정보와 매칭된 도서 목록을 함께 반환할 때 사용.
                    //         추천 컨텍스트와 실제 도서 정보를 결합.
                    .map { (recommendation, $0) }
            }
            // `flatMap` - 매칭된 도서 정보를 최종 모듈 출력으로 변환
            // - Note: 매칭 결과와 GPT 설명을 결합하여 최종 출력을 생성할 때 사용.
            //         1. 추천된 보유 도서들을 실제 보유 도서와 매칭하여 ISBN 추출
            //         2. GPT에 추천 도서 설명을 요청하여 결합
            //         3. BookMatchModuleOutput 형식으로 최종 변환
            .flatMap { [weak self] result -> Single<BookMatchModuleOutput> in
                guard let self else {
                    BookMatchLogger.error(
                        BookMatchError.deinitError,
                        context: "도서 매칭 절차"
                    )

                    return .error(BookMatchError.deinitError)
                }

                let ownedRaws = result.recommendation.ownedBooks.map {
                    RawBook(title: $0.title, author: $0.author)
                }

                let filteredOwnedBooks = result.recommendation.ownedBooks
                    .compactMap { recommendedBook in
                        if let validOwnedBook = ownedBooks
                            .first(where: {
                                $0.title == recommendedBook.title && $0.author == recommendedBook
                                    .author
                            }) {
                            return validOwnedBook.id
                        } else {
                            return nil
                        }
                    }

                let validNewRaws = result.books.map {
                    RawBook(title: $0.title, author: $0.author)
                }

                BookMatchLogger.descriptionStarted()

                return openAiAPI.getDescription(
                    question: question,
                    books: ownedRaws + validNewRaws
                )
                // `map` - 최종 출력 데이터 구조화
                // - Note: GPT 응답과 매칭 결과를 최종 출력 형태로 변환할 때 사용.
                //         1. 중복 제거된 새로운 추천 도서 목록 생성
                //         2. 매칭 완료 로깅 수행
                //         3. ISBN 목록, 새로운 도서 목록, 설명을 포함한 출력 구조체 생성
                //         4. 단일 값 변환이므로 일반 map 사용
                .map { description in
                    let newBooks = Array(Set(result.books))

                    BookMatchLogger.recommendationCompleted(
                        ownedCount: filteredOwnedBooks.count,
                        newCount: newBooks.count
                    )

                    return BookMatchModuleOutput(
                        ownedISBNs: filteredOwnedBooks,
                        newBooks: newBooks,
                        description: description
                    )
                }
            }
            .catch { error in
                BookMatchLogger.error(error, context: "도서 추천")

                if let bookMatchError = error as? BookMatchError {
                    switch bookMatchError {
                    case let .invalidGPTFormat(result):
                        return .error(BookMatchError.invalidGPTFormat(result))
                    case .networkError:
                        return .error(BookMatchError.networkError)
                    case .deinitError:
                        return .error(BookMatchError.deinitError)
                    default:
                        return .just(
                            BookMatchModuleOutput(
                                ownedISBNs: [],
                                newBooks: [],
                                description: bookMatchError.localizedDescription
                            )
                        )
                    }
                } else {
                    return .error(error)
                }
            }
    }
}
