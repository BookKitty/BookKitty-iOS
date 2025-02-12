import Foundation
import RxCocoa
import RxSwift

final class HomeViewModel: ViewModelType {
    // MARK: - Nested Types

    // MARK: - Internal

    struct Input {
        let viewDidLoad: Observable<Void> // 뷰가 로드될 때 전달받은 질문
        let viewWillAppear: Observable<Void> // 뷰가 나타날 때 소유 여부 새로고침
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
        input.viewDidLoad
            .withUnretained(self)
            .map { owner, _ in
                let fetchedBooks = owner.bookRepository.fetchBookList(
                    offset: 0,
                    limit: 5
                )

                return [SectionOfBook(items: fetchedBooks)]
            }
            .bind(to: recommendedBooksRelay)
            .disposed(by: disposeBag)

        // 홈 화면 돌아올 때마다 업데이트
        // 비효율적일 수 있음 주의
        input.viewWillAppear
            .withUnretained(self)
            .map { owner, _ in
                let fetchedBooks = owner.bookRepository.fetchRecentRecommendedBooks()
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
