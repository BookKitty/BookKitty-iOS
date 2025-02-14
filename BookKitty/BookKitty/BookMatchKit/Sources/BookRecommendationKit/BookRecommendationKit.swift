import BookMatchAPI
import BookMatchCore
import BookMatchStrategy
import CoreFoundation
import RxSwift
import UIKit

@_exported import struct BookMatchCore.OwnedBook

/// 도서 매칭 및 추천 기능의 핵심 모듈입니다.
/// 사용자의 요청을 처리하고, 도서 검색, 매칭, 추천 기능을 조율합니다.
public final class BookRecommendationKit: BookRecommendable {
    // MARK: - Properties

    private let titleStrategy = LevenshteinStrategyWithNoParenthesis()
    private let authorStrategy = LevenshteinStrategy()

    private let naverAPI: NaverAPI
    private let openAiAPI: OpenAIAPI
    private let similiarityThreshold: [Double]
    private let maxRetries: Int
    private let titleWeight: Double

    // MARK: - Lifecycle

    public init(
        naverClientId: String,
        naverClientSecret: String,
        openAIApiKey: String,
        similiarityThreshold: [Double] = [0.4, 0.8],
        maxRetries: Int = 3,
        titleWeight: Double = 0.8
    ) {
        let apiConfig = APIConfiguration(
            naverClientId: naverClientId,
            naverClientSecret: naverClientSecret,
            openAIApiKey: openAIApiKey
        )

        naverAPI = NaverAPI(configuration: apiConfig)
        openAiAPI = OpenAIAPI(configuration: apiConfig)

        self.similiarityThreshold = similiarityThreshold
        self.maxRetries = maxRetries
        self.titleWeight = titleWeight
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
            .flatMap { [weak self] result -> Single<[BookItem]> in
                guard let self else {
                    return .just([])
                }

                return Observable.from(result.books)
                    .flatMap { book -> Single<BookItem?> in
                        self.matchToRealBook(book)
                    }
                    .compactMap { $0 }
                    .toArray()
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
            .do(onSuccess: { result in
                let resultString = """
                보유 도서 기반 추천 목록: \(result.ownedBooks.map(\.title))
                미보유 도서 기반 추천 목록: \(result.newBooks.map(\.title))
                """

                BookMatchLogger.gptResponseReceived(result: resultString)
            })
            .flatMap { [weak self] recommendation -> Single<(
                recommendation: RecommendationForQuestion,
                books: [BookItem]
            )> in
                guard let self else {
                    BookMatchLogger.errorOccurred(
                        BookMatchError.referenceDeinitError,
                        context: "추천 절차"
                    )

                    return .error(BookMatchError.referenceDeinitError)
                }

                var previousBooks = recommendation.newBooks

                return Observable.from(recommendation.newBooks)
                    .concatMap { book -> Observable<BookItem?> in
                        self.matchToRealBook(
                            book: book,
                            question: question,
                            previousBooks: previousBooks
                        )
                        .asObservable()
                        .do(onNext: { _ in
                            previousBooks.append(book)
                        })
                    }
                    .compactMap { $0 }
                    .toArray()
                    .map { (recommendation, $0) }
            }
            .flatMap { [weak self] result -> Single<BookMatchModuleOutput> in
                guard let self else {
                    BookMatchLogger.errorOccurred(
                        BookMatchError.referenceDeinitError,
                        context: "도서 매칭 절차"
                    )

                    return .error(BookMatchError.referenceDeinitError)
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
                BookMatchLogger.errorOccurred(error, context: "도서 추천")

                if let bookMatchError = error as? BookMatchError {
                    switch bookMatchError {
                    case .invalidGPTFormat:
                        return .error(BookMatchError.invalidGPTFormat)
                    case .networkError:
                        return .error(BookMatchError.networkError)
                    case .referenceDeinitError:
                        return .error(BookMatchError.referenceDeinitError)
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

    /// 단일 도서에 대해 매칭을 시도하고, 매칭 실패시 추가 도서를 요청하여 재시도합니다.
    /// 모든 재시도가 실패하면 수집된 후보군 중 가장 유사도가 높은 도서를 반환합니다.
    ///
    /// - Parameters:
    ///   - book: 매칭을 시도할 기본 도서 정보
    ///   - question: 사용자의 도서 추천 요청 질문
    ///   - previousBooks: 이전에 시도된 도서들의 목록
    /// - Returns: 매칭된 도서 정보를 포함한 Single 스트림
    ///           성공적으로 매칭된 경우 해당 도서,
    ///           실패한 경우 후보군 중 최상위 도서 또는 nil 반환
    private func matchToRealBook(
        book: RawBook,
        question: String,
        previousBooks: [RawBook]
    ) -> Single<BookItem?> {
        BookMatchLogger.bookConversionStarted(title: book.title, author: book.author)

        var retryCount = 0
        var currentBook = book
        var candidates = [(BookItem, Double)]()

        func tryMatch() -> Single<BookItem?> {
            guard retryCount < maxRetries else {
                candidates.sort(by: { $0.1 > $1.1 })
                return .just(candidates.first?.0)
            }

            return convertToRealBook(currentBook)
                .flatMap { [weak self] result -> Single<BookItem?> in
                    guard let self else {
                        return .error(BookMatchError.invalidGPTFormat)
                    }

                    if let matchedBook = result.book {
                        if result.isMatching {
                            return .just(matchedBook)
                        } else {
                            candidates.append((matchedBook, result.similarity))
                            retryCount += 1

                            BookMatchLogger.retryingBookMatch(
                                attempt: retryCount,
                                currentBook: matchedBook
                            )

                            return openAiAPI.getAdditionalBook(
                                question: question,
                                previousBooks: previousBooks + [currentBook]
                            )
                            .flatMap { newBook -> Single<BookItem?> in
                                currentBook = newBook
                                return tryMatch()
                            }
                        }
                    } else {
                        return .just(nil)
                    }
                }
        }

        return tryMatch()
    }

    /// 단일 도서에 대해 매칭을 시도하고 후보군을 관리합니다.
    /// 매칭 시도가 실패할 경우, 후보군 중 가장 유사도가 높은 도서를 반환합니다.
    ///
    /// - Parameter book: 매칭을 시도할 기본 도서 정보
    /// - Returns: 매칭된 도서 정보를 포함한 Single 스트림. 매칭 실패시 후보군의 최상위 도서 또는 nil 반환
    private func matchToRealBook(_ book: RawBook) -> Single<BookItem?> {
        var retryCount = 0
        var candidates = [(BookItem, Double)]()

        func tryMatch() -> Single<BookItem?> {
            guard retryCount <= maxRetries else {
                candidates.sort(by: { $0.1 > $1.1 })
                return .just(candidates.first?.0)
            }

            return convertToRealBook(book)
                .map { result -> BookItem? in
                    if result.isMatching, let matchedBook = result.book {
                        return matchedBook
                    } else if let matchedBook = result.book {
                        candidates.append((matchedBook, result.similarity))
                        retryCount += 1
                        return nil
                    } else {
                        retryCount += 1
                        return nil
                    }
                }
                .flatMap { matchedBook -> Single<BookItem?> in
                    if let matchedBook {
                        return .just(matchedBook)
                    }
                    return tryMatch()
                }
        }

        return tryMatch()
    }

    /// RawBook을 실제 BookItem으로 변환합니다.
    /// - Note:``recommendBooks(for:)``, ``recommendBooks(from:)`` 메서드에 사용됩니다.
    ///
    /// - Parameters:
    ///   - input: 변환할 기본 도서 정보
    /// - Returns: 매칭 결과, 찾은 도서 정보, 유사도 점수를 포함한 튜플
    /// - Throws: BookMatchError
    private func convertToRealBook(_ input: RawBook)
        -> Single<(isMatching: Bool, book: BookItem?, similarity: Double)> {
        // Results에 대한 병렬 처리가 필요하므로, Observable 스트림 생성 후, 최종 Single 반환 필요
        searchOverallBooks(from: input)
            .flatMap { searchResults -> Single<[BookItem]> in
                guard !searchResults.isEmpty else {
                    return .error(BookMatchError.noMatchFound)
                }

                return .just(searchResults)
            }
            .flatMap { searchResults in
                Observable.from(searchResults)
                    .flatMap { [weak self] book -> Observable<(BookItem, [Double])> in
                        guard let self else {
                            return .never()
                        }

                        let titleCalculation = titleStrategy.calculateSimilarity(
                            book.title, input.title
                        ).asObservable()

                        let authorCalculation = authorStrategy.calculateSimilarity(
                            book.author, input.author
                        ).asObservable()

                        return Observable.zip(titleCalculation, authorCalculation)
                            .map { titleSimilarity, authorSimilarity in
                                (book, [titleSimilarity, authorSimilarity])
                            }
                    }
                    .toArray()
            }
            .map { [weak self] results -> (isMatching: Bool, book: BookItem?, similarity: Double) in
                guard let self else {
                    return (isMatching: false, book: nil, similarity: 0.0)
                }

                let sortedResults = results
                    .sorted { weightedTotalScore($0.1) > weightedTotalScore($1.1) }

                guard let bestMatch = sortedResults.first else {
                    return (isMatching: false, book: nil, similarity: 0.0)
                }

                let totalSimilarity = weightedTotalScore(bestMatch.1)

                let isMatching = bestMatch.1[0] >= similiarityThreshold[0] && bestMatch
                    .1[1] >= similiarityThreshold[1]

                return (
                    isMatching: isMatching,
                    book: bestMatch.0,
                    similarity: totalSimilarity
                )
            }
            .catch { _ in
                .just((isMatching: false, book: nil, similarity: 0.0))
            }
    }

    /// `제목 & 저자`로 도서를 검색합니다.
    /// - Note: ``convertToRealBook()`` 메서드에 사용됩니다.
    ///
    /// - Parameters:
    ///   - sourceBook: 검색할 도서의 기본 정보
    /// - Returns: 검색된 도서 목록
    /// - Throws: BookMatchError
    private func searchOverallBooks(from sourceBook: RawBook) -> Single<[BookItem]> {
        // title과 author로 병렬 검색을 수행하기 위해 Observable 시영
        Observable<Void>.just(())
            .delay(.milliseconds(500), scheduler: MainScheduler.instance)
            .flatMap { [weak self] _ -> Observable<[BookItem]> in
                guard let self else {
                    return .error(BookMatchError.noMatchFound)
                }
                // title 검색과 author 검색을 동시에 수행
                let titleSearch = naverAPI.searchBooks(query: sourceBook.title, limit: 10)
                    .asObservable()
                let authorSearch = naverAPI.searchBooks(query: sourceBook.author, limit: 10)
                    .asObservable()

                // 결과를 하나의 배열로 병합합니다.
                return Observable.zip(titleSearch, authorSearch)
                    .map { titleResults, authorResults in
                        var searchedResults = [BookItem]()
                        searchedResults.append(contentsOf: titleResults)
                        searchedResults.append(contentsOf: authorResults)
                        return searchedResults
                    }
            }
            .flatMap { searchedResults -> Observable<[BookItem]> in
                let subTitleDivider = [":", "|", "-"]
                // If no results and title contains divider, try searching with main title only
                if searchedResults.isEmpty,
                   !subTitleDivider.filter({ sourceBook.title.contains($0) }).isEmpty,
                   let divider = subTitleDivider.first(where: { sourceBook.title.contains($0) }),
                   let title = sourceBook.title.split(separator: divider).first {
                    return self.naverAPI.searchBooks(query: String(title), limit: 10)
                        .asObservable()
                }

                return Observable.just(searchedResults)
            }
            .asSingle()
    }

    private func weightedTotalScore(_ similarities: [Double]) -> Double {
        let weights = [titleWeight, 1.0 - titleWeight]

        return zip(similarities, weights)
            .map { $0.0 * $0.1 }
            .reduce(0, +)
    }
}
