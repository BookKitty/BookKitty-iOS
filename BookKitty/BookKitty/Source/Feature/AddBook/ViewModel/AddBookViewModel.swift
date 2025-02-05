//
//  AddBookViewModel.swift
//  BookKitty
//
//  Created by 반성준 on 1/31/25.
//

import RxCocoa
import RxSwift

final class AddBookViewModel: ViewModelType {
    // MARK: Internal

    // MARK: - Input & Output

    struct Input {
        let captureButtonTapped: Observable<Void>
        let manualAddButtonTapped: Observable<String> // ✅ 직접 입력한 제목 전달
        let confirmButtonTapped: Observable<Void>
    }

    struct Output {
        let bookList: Observable<[String]>
        let navigateToReviewAddBook: Observable<[String]>
        let showTitleInputPopup: Observable<Void> // ✅ 제목 입력 팝업 트리거
    }

    let disposeBag = DisposeBag() // ✅ internal으로 변경

    // MARK: - Transform Function

    func transform(_ input: Input) -> Output {
        // 📸 OCR 기반으로 책 제목 추가
        input.captureButtonTapped
            .subscribe(onNext: { [weak self] in
                self?.addBook("촬영된 책 제목") // ✅ OCR 연동 가능
            })
            .disposed(by: disposeBag)

        // 📝 사용자가 직접 입력한 책 제목 추가
        input.manualAddButtonTapped
            .subscribe(onNext: { [weak self] title in
                self?.addBook(title)
            })
            .disposed(by: disposeBag)

        // ✅ 제목 입력 팝업 표시 트리거
        input.manualAddButtonTapped
            .map { _ in }
            .bind(to: showTitleInputPopupRelay)
            .disposed(by: disposeBag)

        // ✅ 책 목록을 가져와서 화면 전환 (비어있지 않은 경우만)
        input.confirmButtonTapped
            .withLatestFrom(bookListRelay)
            .filter { !$0.isEmpty }
            .bind(to: navigateToReviewRelay)
            .disposed(by: disposeBag)

        return Output(
            bookList: bookListRelay.asObservable(),
            navigateToReviewAddBook: navigateToReviewRelay.asObservable(),
            showTitleInputPopup: showTitleInputPopupRelay.asObservable() // ✅ 추가
        )
    }

    // MARK: - Public Methods

    func addBook(_ bookTitle: String) {
        var currentList = bookListRelay.value
        if !currentList.contains(bookTitle) { // ✅ 중복 방지
            currentList.append(bookTitle)
            bookListRelay.accept(currentList)
        }
    }

    func deleteBook(at index: Int) {
        var currentList = bookListRelay.value
        if index < currentList.count {
            currentList.remove(at: index)
            bookListRelay.accept(currentList)
        }
    }

    // MARK: Private

    private let bookListRelay = BehaviorRelay<[String]>(value: [])
    private let navigateToReviewRelay = PublishRelay<[String]>()
    private let showTitleInputPopupRelay = PublishRelay<Void>() // ✅ 제목 입력 팝업 트리거 추가
}
