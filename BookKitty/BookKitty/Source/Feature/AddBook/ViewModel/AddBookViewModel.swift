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

    // MARK: - Internal

    // MARK: - Input & Output

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

    // MARK: - Private Properties

    private let bookListRelay = BehaviorRelay<[Book]>(value: [])
    private let navigateToReviewRelay = PublishRelay<[Book]>()
    private let addBookRelay = PublishRelay<String>()

    // MARK: - Lifecycle

    // MARK: - Initializer

    init() {
        addBookRelay
            .subscribe(onNext: { [weak self] title in
                self?.addBook(title: title)
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Functions

    // MARK: - Transform Function

    func transform(_ input: Input) -> Output {
        // 📸 OCR 기반으로 책 제목 추가
        input.captureButtonTapped
            .map { "촬영된 책 제목" }
            .bind(to: addBookRelay)
            .disposed(by: disposeBag)

        // 📝 사용자가 직접 입력한 책 제목 추가
        input.manualAddButtonTapped
            .bind(to: addBookRelay)
            .disposed(by: disposeBag)

        // ✅ 제목 입력 팝업 표시 트리거
        let showPopup = input.manualAddButtonTapped.map { _ in }

        // ✅ 책 목록을 가져와서 화면 전환 (비어있지 않은 경우만)
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

    // MARK: - Private Methods

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
