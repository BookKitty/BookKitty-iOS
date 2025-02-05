//
//  BookCaptureViewModel.swift
//  BookKitty
//
//  Created by 반성준 on 2/5/25.
//

import RxCocoa
import RxSwift

final class BookCaptureViewModel: ViewModelType {
    // MARK: Internal

    struct Input {
        let captureButtonTapped: Observable<Void>
        let manualAddButtonTapped: Observable<Void>
        let confirmButtonTapped: Observable<Void>
        let enteredTitle: Observable<String>
    }

    struct Output {
        let navigateToReview: Observable<[String]>
        let showTitleInputPopup: Observable<Void>
    }

    let disposeBag = DisposeBag()

    func transform(_ input: Input) -> Output {
        input.captureButtonTapped
            .map { ["촬영된 책 제목 1", "촬영된 책 제목 2"] } // ✅ OCR 연동 가능
            .bind(to: capturedBooksRelay)
            .disposed(by: disposeBag)

        input.manualAddButtonTapped
            .bind(to: showTitleInputPopupRelay)
            .disposed(by: disposeBag)

        input.enteredTitle
            .withLatestFrom(capturedBooksRelay) { newTitle, currentList in
                currentList + [newTitle]
            }
            .bind(to: capturedBooksRelay)
            .disposed(by: disposeBag)

        return Output(
            navigateToReview: input.confirmButtonTapped.withLatestFrom(capturedBooksRelay),
            showTitleInputPopup: showTitleInputPopupRelay.asObservable()
        )
    }

    func addCapturedBook(_ bookTitle: String) {
        var currentList = capturedBooksRelay.value
        currentList.append(bookTitle)
        capturedBooksRelay.accept(currentList)
    }

    // MARK: Private

    private let capturedBooksRelay = BehaviorRelay<[String]>(value: [])
    private let showTitleInputPopupRelay = PublishRelay<Void>()
}
