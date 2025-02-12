import Foundation
import RxCocoa
import RxSwift

final class HomeViewModel: ViewModelType {
    // MARK: - Nested Types

    // MARK: - Internal

    struct Input {
        let viewWillAppear: Observable<Void> // 뷰가 로드될 때 전달받은 질문
        let bookSelected: Observable<Book> // 사용자가 선택한 책
    }

    struct Output {
        let recommendedBooks: Driver<[SectionOfBook]> // 추천된 책 목록
        let error: Observable<Error> // 에러 처리
    }

    // MARK: - Properties

    let disposeBag = DisposeBag()

    let navigateToBookDetail = PublishRelay<Book>()

    // MARK: - Private

    private let bookRepository: BookRepository

    private let recommendedBooksRelay = BehaviorRelay<[SectionOfBook]>(value: [])
    private let errorRelay = PublishRelay<Error>()

    // MARK: - Lifecycle

    init(
        bookRepository: BookRepository
    ) {
        self.bookRepository = bookRepository
    }

    // MARK: - Functions

    func transform(_ input: Input) -> Output {
        input.viewWillAppear
            .withUnretained(self)
            .map { _ in
                let fetchedBooks = self.bookRepository.fetchRecentRecommendedBooks()
                return [SectionOfBook(items: fetchedBooks)]
            }
            .bind(to: recommendedBooksRelay)
            .disposed(by: disposeBag)

        input.bookSelected
            .bind(to: navigateToBookDetail) // 책 상세 화면으로 이동
            .disposed(by: disposeBag)

        return Output(
            recommendedBooks: recommendedBooksRelay.asDriver(),
            error: errorRelay.asObservable()
        )
    }
}
