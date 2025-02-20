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

    let navigationBackRelay = PublishRelay<Void>()
    let navigationAfterBookAddedRelay = PublishRelay<Void>()

    private let booksRelay = BehaviorRelay<[Book]>(value: [])
    private let bookRepository: BookRepository
    private let bookOcrKit: BookMatchable

    // MARK: - Lifecycle

    init(bookRepository: BookRepository, bookOcrKit: BookMatchable) {
        self.bookRepository = bookRepository
        self.bookOcrKit = bookOcrKit
    }

    // MARK: - Functions

    func transform(_ input: Input) -> Output {
        input.backButtonTapped
            .bind(to: navigationBackRelay)
            .disposed(by: disposeBag)

        input.addBookButtonTapped
            .withUnretained(self)
            .map { owner, book in
                BookKittyLogger.log("책 추가 버튼 탭")
                _ = owner.bookRepository.saveBook(book: book)
                _ = owner.bookRepository.addBookToShelf(isbn: book.isbn)
                // TODO: 에러 처리
            }
            .bind(to: navigationAfterBookAddedRelay)
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
