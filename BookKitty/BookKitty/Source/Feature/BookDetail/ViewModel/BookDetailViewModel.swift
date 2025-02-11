//
//  BookDetailViewModel.swift
//  BookKitty
//
//  Created by 전성규 on 1/27/25.
//

import Foundation
import RxCocoa
import RxRelay
import RxSwift

final class BookDetailViewModel: ViewModelType {
    // MARK: - Nested Types

    // MARK: - Internal

    struct Input {
        let viewDidLoad: Observable<Void>
        let leftBarButtonTapTrigger: Observable<Void>
        let popupViewConfirmButtonTapTrigger: Observable<Void>
    }

    struct Output {
        let bookDetail: PublishRelay<Book>
    }

    // MARK: - Properties

    let disposeBag = DisposeBag()
    let navigateBackRelay = PublishRelay<Void>()

    private var bookDetail: Book

    // MARK: - Private

    private let bookDetailRelay = PublishRelay<Book>() // TODO: TestBookModel -> Book
    private let bookRepository: BookRepository

    // MARK: - Lifecycle

    init(bookDetail: Book, bookRepository: BookRepository) {
        self.bookDetail = bookDetail
        self.bookRepository = bookRepository
    }

    // MARK: - Functions

    func transform(_ input: Input) -> Output {
        input.viewDidLoad
            .withUnretained(self)
            .map { owner, _ in owner.bookDetail }
            .bind(to: bookDetailRelay)
            .disposed(by: disposeBag)

        input.leftBarButtonTapTrigger
            .bind(to: navigateBackRelay)
            .disposed(by: disposeBag)

        input.popupViewConfirmButtonTapTrigger
            .withUnretained(self)
            .do(onNext: { _ in
                let bookDetail = self.bookDetail
                switch bookDetail.isOwned {
                // TODO: 오류 처리
                case true:
                    _ = self.bookRepository.exceptBookFromShelf(isbn: bookDetail.isbn)
                case false:
                    _ = self.bookRepository.addBookToShelf(isbn: bookDetail.isbn)
                }
            })
            .map { _ in }
            .bind(to: navigateBackRelay)
            .disposed(by: disposeBag)

        return Output(bookDetail: bookDetailRelay)
    }
}
