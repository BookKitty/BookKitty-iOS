//
//  BookDetailViewModel.swift
//  BookKitty
//
//  Created by 전성규 on 1/27/25.
//

import Foundation
import LogKit
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
            .do(onNext: { owner, _ in
                let bookDetail = owner.bookDetail
                switch bookDetail.isOwned {
                // TODO: 오류 처리
                case true:
                    if !owner.bookRepository.exceptBookFromShelf(isbn: bookDetail.isbn) {
                        LogKit.error("책장에서 책 제외 실패")
                    }
                case false:
                    if !owner.bookRepository.addBookToShelf(isbn: bookDetail.isbn) {
                        LogKit.error("책장에 책 추가 실패")
                    }
                }
            })
            .map { _ in }
            .bind(to: navigateBackRelay)
            .disposed(by: disposeBag)

        return Output(bookDetail: bookDetailRelay)
    }
}
