import BookMatchAPI
import BookMatchCore
import RxSwift

public protocol BookValidatable {
    func findMatchingBookWithRetry(
        book: RawBook,
        question: String,
        previousBooks: [RawBook],
        openAiAPI: OpenAIAPI
    ) -> Single<BookItem?>

    func validateRecommendedBook(_ input: RawBook)
        -> Single<(isMatching: Bool, book: BookItem?, similarity: Double)>
}
