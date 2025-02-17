import BookMatchAPI
import BookMatchCore
import BookMatchStrategy
import RxSwift

public final class BookValidationService: BookValidatable {
    // MARK: - Properties

    private let similiarityThreshold: [Double]
    private let maxRetries: Int
    private let titleWeight: Double
    private let searchService: BookSearchService

    // MARK: - Lifecycle

    init(
        similiarityThreshold: [Double],
        maxRetries: Int,
        titleWeight: Double,
        searchService: BookSearchService
    ) {
        self.similiarityThreshold = similiarityThreshold
        self.maxRetries = maxRetries
        self.titleWeight = titleWeight
        self.searchService = searchService
    }

    // MARK: - Functions

    /// ``recommendBooks(for: _, from: _)``메서드에 사용됩니다,
    /// 단일 도서에 대해 매칭을 시도하고, 매칭 실패시 `추가 도서를 요청`하여 재시도합니다.
    /// 모든 재시도가 실패하면 수집된 후보군 중 가장 유사도가 높은 도서를 반환합니다.
    ///
    /// - Parameters:
    ///   - book: 매칭을 시도할 기본 도서 정보
    ///   - question: 사용자의 도서 추천 요청 질문
    ///   - previousBooks: 이전에 시도된 도서들의 목록
    ///   - openAiAPI: 추가 도서 요청을 위한 openAI 클라이언트
    /// - Returns: 매칭된 도서 정보를 포함한 Single 스트림
    ///           성공적으로 매칭된 경우 해당 도서,
    ///           실패한 경우 후보군 중 최상위 도서 또는 nil 반환
    public func findMatchingBookWithRetry(
        book: RawBook,
        question: String,
        previousBooks: [RawBook],
        openAiAPI: OpenAIAPI
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

            return validateRecommendedBook(currentBook)
                // `flatMap` - 매칭 결과 처리 및 재시도 로직
                // - Note: 도서 매칭 결과에 따른 후속 처리를 결정할 때 사용.
                //         1. 매칭 성공 시 해당 도서 반환
                //         2. 부분 매칭 시 후보 목록에 추가하고 새로운 도서 요청
                //         3. 매칭 실패 시 nil 반환
                .flatMap { result -> Single<BookItem?> in
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

    /// ``recommendBooks(from:_)``메서드에 사용됩니다,
    /// RawBook을 실제 BookItem으로 변환합니다.
    /// - Parameters:
    ///   - input: 변환할 기본 도서 정보
    /// - Returns: 매칭 결과, 찾은 도서 정보, 유사도 점수를 포함한 튜플
    /// - Throws: BookMatchError
    public func validateRecommendedBook(_ input: RawBook)
        -> Single<(isMatching: Bool, book: BookItem?, similarity: Double)> {
        // Results에 대한 병렬 처리가 필요하므로, Observable 스트림 생성 후, 최종 Single 반환 필요
        searchService.searchByTitleAndAuthor(from: input)
            // `flatMap` - 검색 결과 변환 및 유사도 계산
            // - Note: 검색된 도서들의 유사도를 계산하여 새로운 스트림으로 변환할 때 사용.
            //         1. 검색 결과가 비어있는지 확인
            //         2. 각 도서에 대해 제목과 저자 유사도 계산
            //         3. 계산된 결과를 새로운 스트림으로 반환
            .flatMap { searchResults -> Single<[(BookItem, [Double])]> in
                guard !searchResults.isEmpty else {
                    return .error(BookMatchError.noMatchFound)
                }

                let result = searchResults.map { book in
                    let titleSimilarity = LevenshteinStrategyNoParenthesis.calculateSimilarity(
                        book.title, input.title
                    )

                    let authorSimilarity = LevenshteinStrategy.calculateSimilarity(
                        book.author, input.author
                    )
                    return (book, [titleSimilarity, authorSimilarity])
                }

                return .just(result)
            }
            // `map` - 유사도 기반 최적 매칭 선택
            // - Note: 계산된 유사도를 바탕으로 최적의 매칭을 선택할 때 사용.
            //         1. 결과를 유사도 점수로 정렬
            //         2. 최상위 매칭 선택
            //         3. 매칭 임계값 검사 수행
            //         4. 최종 매칭 결과 구조체 반환
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
}

extension BookValidationService {
    private func weightedTotalScore(_ similarities: [Double]) -> Double {
        let weights = [titleWeight, 1.0 - titleWeight]

        return zip(similarities, weights)
            .map { $0.0 * $0.1 }
            .reduce(0, +)
    }
}
