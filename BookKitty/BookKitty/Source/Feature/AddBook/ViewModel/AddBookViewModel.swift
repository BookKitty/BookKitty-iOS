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

    struct Input {
        let captureButtonTapped: Observable<Void>
        let manualAddButtonTapped: Observable<Void>
        let confirmButtonTapped: Observable<Void>
    }

    struct Output {
        let bookList: Observable<[String]>
        let navigateToReviewAddBook: Observable<[String]>
    }

    let disposeBag = DisposeBag()

    func transform(_ input: Input) -> Output {
        // ✅ 책 추가 버튼 클릭 시 책 제목을 입력받아 리스트에 추가
        input.manualAddButtonTapped
            .subscribe(onNext: { [weak self] in
                self?.addBook("새로운 책")
            })
            .disposed(by: disposeBag)

        // ✅ confirmButtonTapped가 실행될 때 현재 bookList 값을 방출
        input.confirmButtonTapped
            .withLatestFrom(bookListRelay)
            .subscribe(onNext: { [weak self] bookList in
                self?.navigateToReviewAddBookRelay.accept(bookList) // ✅ Relay 값을 즉시 업데이트
            })
            .disposed(by: disposeBag)

        return Output(
            bookList: bookListRelay.asObservable(),
            navigateToReviewAddBook: navigateToReviewAddBookRelay
                .compactMap { $0 } // ✅ nil 값 필터링
                .asObservable()
        )
    }

    /// ✅ 책 추가 기능
    func addBook(_ bookTitle: String) {
        var currentList = bookListRelay.value
        currentList.append(bookTitle)
        bookListRelay.accept(currentList)
    }

    // MARK: Private

    // ✅ `BehaviorRelay<[String]?>`로 변경하여 이전 값 유지 가능하도록 수정
    private let bookListRelay = BehaviorRelay<[String]>(value: [])
    private let navigateToReviewAddBookRelay = BehaviorRelay<[String]?>(value: nil) // ✅ 옵셔널 처리
}
