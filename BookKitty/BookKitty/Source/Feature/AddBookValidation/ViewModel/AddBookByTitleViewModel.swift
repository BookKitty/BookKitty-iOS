//
//  AddBookByTitleViewModel.swift
//  BookKitty
//
//  Created by 권승용 on 2/17/25.
//

import BookOCRKit
import Foundation
import RxCocoa
import RxSwift

final class AddBookByTitleViewModel: ViewModelType {
    // MARK: - Nested Types

    struct Input {
        let backButtonTapped: Observable<Void>
        let addBookButtonTapped: Observable<Book>
        let searchResult: Observable<String>
    }

    struct Output {
        let books: Driver<[Book]>
    }

    // MARK: - Properties

    let disposeBag = DisposeBag()

    private let booksRelay = BehaviorRelay<[Book]>(value: [])
    private let repository = MockBookRepository()
    private let bookOcrKit: BookMatchable

    private let navigationBackRelay = PublishRelay<Void>()
    private let navigationBackWithBookRelay = PublishRelay<Book>()

    // MARK: - Lifecycle

    init(bookOcrKit: BookMatchable) {
        self.bookOcrKit = bookOcrKit
    }

    // MARK: - Functions

    func transform(_ input: Input) -> Output {
        input.backButtonTapped
            .map {
                BookKittyLogger.log("뒤로가기 버튼 탭")
            }
            .bind(to: navigationBackRelay)
            .disposed(by: disposeBag)

        input.addBookButtonTapped
            .withUnretained(self)
            .map { _, book in
                BookKittyLogger.log("책 추가 버튼 탭")
                return book
            }
            .bind(to: navigationBackWithBookRelay)
            .disposed(by: disposeBag)

        input.searchResult
            .withUnretained(self)
            .flatMapLatest { owner, searchResult in
                owner.bookOcrKit.searchBookFromText(searchResult)
            }
            .map { bookItems in
                bookItems.map {
                    Book(
                        isbn: $0.isbn,
                        title: $0.title,
                        author: $0.author,
                        publisher: $0.publisher,
                        thumbnailUrl: URL(string: $0.image),
                        isOwned: false,
                        createdAt: Date(),
                        updatedAt: Date()
                    )
                }
            }
            .bind(to: booksRelay)
            .disposed(by: disposeBag)

        return Output(
            books: booksRelay.asDriver()
        )
    }
}
