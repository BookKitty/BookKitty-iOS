//
//  BookCaptureViewModel.swift
//  BookKitty
//
//  Created by 반성준 on 2/5/25.
//

import RxCocoa
import RxSwift

final class BookCaptureViewModel: ViewModelType {
    // MARK: - Nested Types

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

    // MARK: - Properties

    let disposeBag = DisposeBag()

    // MARK: - Private

    private let capturedBooksRelay = BehaviorRelay<[String]>(value: [])
    private let showTitleInputPopupRelay = PublishRelay<Void>()

    // MARK: - Functions

    func transform(_ input: Input) -> Output {
        input.captureButtonTapped
            .subscribe(onNext: { [weak self] in
                // 캡처 버튼 탭 시 실제로는 아무 동작 안함 (이미 ViewController에서 처리)
            })
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

    func addCapturedBooks(_ titles: [String]) {
        var currentList = capturedBooksRelay.value
        currentList.append(contentsOf: titles)
        capturedBooksRelay.accept(currentList)
    }
}
