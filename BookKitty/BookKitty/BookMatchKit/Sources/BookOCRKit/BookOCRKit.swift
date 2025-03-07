import BookMatchAPI
import BookMatchCore
import BookMatchService
import BookMatchStrategy
import RxSwift
import UIKit

@_exported import struct BookMatchCore.OwnedBook

/// 도서 `매칭` 기능의 핵심 모듈입니다.
/// 사용자의 요청을 처리하고, 도서 검색, `매칭` 기능을 조율합니다.
public final class BookOCRKit: BookMatchable {
    // MARK: - Properties

    private let imageDownloadAPI: ImageDownloadAPI

    private let serviceFactory: ServiceFactory
    private let searchService: BookSearchable
    private let textExtractionService: TextExtractable

    // MARK: - Lifecycle

    public init(
        naverClientId: String,
        naverClientSecret: String
    ) {
        serviceFactory = ServiceFactory(
            naverClientId: naverClientId,
            naverClientSecret: naverClientSecret,
            openAIApiKey: ""
        )

        searchService = serviceFactory.makeBookSearchService()
        imageDownloadAPI = serviceFactory.makeImageDownloadAPI()
        textExtractionService = serviceFactory.makeTextExtractionService()
    }

    // MARK: - Functions

    // MARK: - Public

    /// `OCR로 인식된 텍스트 데이터와 이미지`를 기반으로 실제 도서를 `매칭`합니다.
    ///
    /// - Parameters:
    ///   - image: 도서 표지 이미지
    /// - Returns: 매칭된 도서 정보 또는 nil
    /// - Throws: 초기 단어부터 검색된 결과가 나오지 않을 때
    public func recognizeBookFromImage(_ image: UIImage) -> Single<BookItem> {
        BookMatchLogger.matchingStarted()

        return textExtractionService.extractText(from: image)
            // `flatMap` - 텍스트 추출 결과를 도서 검색 결과로 변환
            // - Note: OCR로 추출된 텍스트를 사용하여 `도서 검색을 수행`할 때 사용.
            //         텍스트 배열을 받아서 새로운 Single<[BookItem]> 스트림을 생성.
            //         메모리 해제 검사와 빈 결과 처리도 함께 수행.
            .flatMap { [weak self] textData -> Single<[BookItem]> in
                guard let self else {
                    return .error(BookMatchError.deinitError)
                }

                return searchService.searchProgressively(from: textData)
                    .flatMap { results in
                        guard !results.isEmpty else { // 유의미한 책 검색결과가 나오지 않았을 경우, 에러를 반환합니다
                            BookMatchLogger.error(
                                BookMatchError.noMatchFound,
                                context: "Book Search"
                            )

                            return .error(BookMatchError.noMatchFound)
                        }

                        BookMatchLogger.searchResultsReceived(count: results.count)
                        return .just(results)
                    }
            }
            // `flatMap` - 검색된 도서들에 대해 이미지 유사도 계산
            // - Note: 각 검색 결과에 대해 `이미지를 다운로드`하고 유사도를 계산할 때 사용.
            //         Observable.from()으로 배열을 개별 요소로 분리하고,
            //         flatMap으로 각 도서에 대한 이미지 다운로드와 유사도 계산을 수행.
            .flatMap { books in
                Observable.from(books)
                    .flatMap { [weak self] book -> Single<(BookItem, Double)> in
                        guard let self else {
                            return .error(BookMatchError.deinitError)
                        }

                        // - Note: imageDownloadFailed 에러를 반환할 수 있는 메서드입니다.
                        return imageDownloadAPI.downloadImage(from: book.image)
                            .flatMap { downloadedImage -> Single<(BookItem, Double)> in
                                let similarity = ImageVisionStrategy.calculateSimilarity(
                                    image,
                                    downloadedImage
                                )

                                BookMatchLogger.similarityCalculated(
                                    bookTitle: book.title,
                                    score: similarity
                                )

                                return .just((book, similarity))
                            }
                    }
                    // `toArray` - 개별 결과들을 배열로 변환
                    // - Note: 각각의 (BookItem, Double) 튜플을 하나의  `배열로 모을 때` 사용.
                    //         모든 이미지 유사도 계산이 완료된 후 한 번에 결과를 처리하기 위함.
                    .toArray()
            }
            // `map` - 최종 결과 변환
            // - Note: 유사도가 계산된 도서들 중 가장 높은 유사도를 가진 도서를 선택할 때 사용.
            //         sorted로 유사도 기준 내림차순 정렬 후 첫 번째 도서 선택.
            .map { (results: [(BookItem, Double)]) -> BookItem in
                guard let bestMatchedBook = results.sorted(by: { $0.1 > $1.1 }).first?.0 else {
                    throw BookMatchError.noMatchFound
                }

                BookMatchLogger.matchingCompleted(success: true, bookTitle: bestMatchedBook.title)
                return bestMatchedBook
            }
    }

    public func searchBookFromText(_ query: String) -> Single<[BookItem]> {
        searchService.searchByQuery(from: query)
    }
}
