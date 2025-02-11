//
//  AddBookViewModel.swift
//  BookKitty
//
//  Created by 반성준 on 1/31/25.
//

import Foundation
import RxCocoa
import RxSwift

final class AddBookViewModel: ViewModelType {
    // MARK: - Nested Types

    struct Input {
        let captureButtonTapped: Observable<Void>
        let manualAddButtonTapped: Observable<String>
        let confirmButtonTapped: Observable<Void>
    }

    struct Output {
        let bookList: Observable<[Book]>
        let navigateToReviewAddBook: Observable<[Book]>
        let showTitleInputPopup: Observable<Void>
    }

    // MARK: - Properties

    let disposeBag = DisposeBag()

    // MARK: - Private

    private let bookListRelay = BehaviorRelay<[Book]>(value: [])
    private let navigateToReviewRelay = PublishRelay<[Book]>()
    private let addBookRelay = PublishRelay<String>()

    // MARK: - Lifecycle

    init() {
        addBookRelay
            .subscribe(onNext: { [weak self] title in
                self?.addBook(title: title)
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Functions

    func transform(_ input: Input) -> Output {
        input.captureButtonTapped
            .withLatestFrom(addBookRelay)
            .bind(to: addBookRelay)
            .disposed(by: disposeBag)

        input.manualAddButtonTapped
            .bind(to: addBookRelay)
            .disposed(by: disposeBag)

        let showPopup = input.manualAddButtonTapped.map { _ in }

        input.confirmButtonTapped
            .withLatestFrom(bookListRelay)
            .filter { !$0.isEmpty }
            .bind(to: navigateToReviewRelay)
            .disposed(by: disposeBag)

        return Output(
            bookList: bookListRelay.asObservable(),
            navigateToReviewAddBook: navigateToReviewRelay.asObservable(),
            showTitleInputPopup: showPopup
        )
    }

    private func addBook(title: String) {
        let newBook = Book(
            isbn: UUID().uuidString,
            title: title,
            author: "알 수 없음",
            publisher: "알 수 없음",
            thumbnailUrl: nil
        )

        var currentList = bookListRelay.value
        if !currentList.contains(where: { $0.title == title }) {
            currentList.append(newBook)
            bookListRelay.accept(currentList)
        }
    }
}
