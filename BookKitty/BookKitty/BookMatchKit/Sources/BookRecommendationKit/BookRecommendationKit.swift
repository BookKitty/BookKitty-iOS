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
    // MARK: Lifecycle

    public init(
        naverClientId: String,
        naverClientSecret: String,
        openAIApiKey: String,
        configuration: BookMatchConfiguration = .default
    ) {
        self.configuration = configuration

        let config = APIConfiguration(
            naverClientId: naverClientId,
            naverClientSecret: naverClientSecret,
            openAIApiKey: openAIApiKey
        )

        apiClient = DefaultAPIClient(configuration: config)
    }

    // MARK: Public

    /// `보유 도서 목록`을 기반으로 새로운 도서를 `추천`합니다.
    ///
    /// - Parameters:
    ///   - ownedBooks: 사용자가 보유한 도서 목록
    /// - Returns: 추천된 도서 목록
    public func recommendBooks(from ownedBooks: [OwnedBook]) async -> [BookItem] {
        do {
            let startTime = Date().timeIntervalSince1970
            let result = try await apiClient.getBookRecommendation(ownedBooks: ownedBooks).value

            var validNewBooks = [BookItem]()
            var previousBooks = result.books

            for book in result.books {
                var retryCount = 0
                var candidates = [(BookItem, Double)]()

                while retryCount <= configuration.maxRetries {
                    if retryCount == configuration.maxRetries {
                        candidates.sort(by: { $0.1 > $1.1 })
                        if let bestCandidate = candidates.first {
                            validNewBooks.append(bestCandidate.0)
                        }
                        break
                    }

                    let (isMatching, matchedBook, similarity) = try await convertToRealBook(book)
                    previousBooks.append(book)

                    if isMatching, let matchedBook {
                        validNewBooks.append(matchedBook)
                        break
                    } else if !isMatching, let matchedBook {
                        candidates.append((matchedBook, similarity))
                        retryCount += 1
                    }
                }
            }
            print("elapsedTime:\(Date().timeIntervalSince1970 - startTime)")
            return Array(Set(validNewBooks))
        } catch {
            print("error in recommendBooksFromOwnedBooks")
            return []
        }
    }

    /// 사용자의 `질문`과 보유 도서를 기반으로 도서를 `추천`합니다.
    ///
    /// - Parameters:
    ///   - input: 사용자의 질문과 보유 도서 정보를 포함한 입력 데이터
    /// - Returns: 추천된 도서 목록과 설명을 포함한 출력 데이터
    /// - Throws: BookMatchError.questionShort (질문이 4글자 미만인 경우)
    public func recommendBooks(for question: String, from ownedBooks: [OwnedBook]) async -> BookMatchModuleOutput {
        do {
            let startTime = Date().timeIntervalSince1970
            guard question.count >= 4 else {
                throw BookMatchError.questionShort
            }

            let recommendation = try await apiClient.getBookRecommendation(
                question: question,
                ownedBooks: ownedBooks
            ).value

            var validNewBooks = [BookItem]()
            var previousBooks = recommendation.newBooks

            for book in recommendation.newBooks {
                var retryCount = 0
                var currentBook = book
                var candidates = [(BookItem, Double)]()

                while retryCount <= configuration.maxRetries {
                    if retryCount == configuration.maxRetries {
                        candidates.sort(by: { $0.1 > $1.1 })
                        if let bestCandidate = candidates.first {
                            validNewBooks.append(bestCandidate.0)
                        }
                        break
                    }

                    let (
                        isMatching,
                        matchedBook,
                        similarity
                    ) = try await convertToRealBook(currentBook)
                    previousBooks.append(currentBook)

                    if isMatching, let matchedBook {
                        validNewBooks.append(matchedBook)
                        break
                    } else if !isMatching, let matchedBook {
                        candidates.append((matchedBook, similarity))

                        currentBook = try await apiClient.getAdditionalBook(
                            question: question,
                            previousBooks: previousBooks
                        )
                        .value

                        retryCount += 1
                    }
                }
            }

            let ownedRaws = recommendation.ownedBooks.map { RawBook(
                title: $0.title,
                author: $0.author
            ) }
            let validNewRaws = validNewBooks.map { RawBook(title: $0.title, author: $0.author) }

            let description = try await apiClient.getDescription(
                question: question,
                books: ownedRaws + validNewRaws
            )
            .value

            print("elapsedTime:\(Date().timeIntervalSince1970 - startTime)")

            return BookMatchModuleOutput(
                ownedISBNs: ownedBooks.map(\.id),
                newBooks: Array(Set(validNewBooks)),
                description: description
            )
        } catch {
            let description: String

            if let bookMatchError = error as? BookMatchError {
                description = bookMatchError.description
            } else {
                description = error.localizedDescription
            }

            return BookMatchModuleOutput(
                ownedISBNs: [],
                newBooks: [],
                description: description
            )
        }
    }

    // MARK: Private

    private let apiClient: APIClientProtocol
    private let titleStrategy = LevenshteinStrategyWithNoParenthesis()
    private let authorStrategy = LevenshteinStrategy()
    private let configuration: BookMatchConfiguration

    /// RawBook을 실제 BookItem으로 변환합니다.
    /// - Note:``recommendBooks(for:)``, ``recommendBooks(from:)`` 메서드에 사용됩니다.
    ///
    /// - Parameters:
    ///   - input: 변환할 기본 도서 정보
    /// - Returns: 매칭 결과, 찾은 도서 정보, 유사도 점수를 포함한 튜플
    /// - Throws: BookMatchError
    private func convertToRealBook(_ input: RawBook) async throws
        -> (isMatching: Bool, book: BookItem?, similarity: Double) {
        let searchResults = try await searchOverallBooks(from: input)
            .value // Single을 async/await로 변환

        guard !searchResults.isEmpty else {
            return (isMatching: false, book: nil, similarity: 0.0)
        }

        let results = try await Observable.merge(
            searchResults.map { book -> Observable<(BookItem, [Double])> in
                Observable.zip(
                    titleStrategy.calculateSimilarity(book.title, input.title).asObservable(),
                    authorStrategy.calculateSimilarity(book.author, input.author).asObservable()
                )
                .map { titleSimilarity, authorSimilarity in
                    let similarities = [titleSimilarity, authorSimilarity]
                    return (book, similarities)
                }
            }
        )
        .toArray()
        .value

        let sortedResults = results.sorted {
            weightedTotalScore($0.1) > weightedTotalScore($1.1)
        }

        guard let bestMatch = sortedResults.first else {
            return (isMatching: false, book: nil, similarity: 0.0)
        }

        let totalSimilarity = weightedTotalScore(bestMatch.1)
        let isMatching = bestMatch.1[0] >= configuration.titleSimilarityThreshold && bestMatch
            .1[1] >= configuration.authorSimilarityThreshold

        return (
            isMatching: isMatching,
            book: bestMatch.0,
            similarity: totalSimilarity
        )
    }

    /// `제목 & 저자`로 도서를 검색합니다.
    /// - Note: ``convertToRealBook()`` 메서드에 사용됩니다.
    ///
    /// - Parameters:
    ///   - sourceBook: 검색할 도서의 기본 정보
    /// - Returns: 검색된 도서 목록
    /// - Throws: BookMatchError
    private func searchOverallBooks(from sourceBook: RawBook) -> Single<[BookItem]> {
        Observable<Void>.just(())
            .delay(.milliseconds(500), scheduler: MainScheduler.instance)
            .flatMap { _ -> Observable<[BookItem]> in
                // Search by title and author in parallel
                let titleSearch = self.apiClient.searchBooks(query: sourceBook.title, limit: 10)
                    .asObservable()
                let authorSearch = self.apiClient.searchBooks(query: sourceBook.author, limit: 10)
                    .asObservable()

                // Combine results from both searches
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
                    return self.apiClient.searchBooks(query: String(title), limit: 10)
                        .asObservable()
                }

                return Observable.just(searchedResults)
            }
            .asSingle()
    }

    private func weightedTotalScore(_ similarities: [Double]) -> Double {
        let weights = [0.8, 0.2] // 제목 가중치 0.8, 저자 가중치 0.2
        return zip(similarities, weights)
            .map { $0.0 * $0.1 }
            .reduce(0, +)
    }
}
