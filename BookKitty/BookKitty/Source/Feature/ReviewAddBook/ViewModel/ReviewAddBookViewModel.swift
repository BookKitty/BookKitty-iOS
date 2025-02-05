//
//  ReviewAddBookViewModel.swift
//  BookKitty
//
//  Created by 반성준 on 1/31/25.
//

import Foundation
import RxCocoa
import RxSwift

final class ReviewAddBookViewModel: ViewModelType {
    // MARK: Lifecycle

    init(initialBookList: [String]) {
        bookListRelay.accept(initialBookList)
    }

    // MARK: Internal

    struct Input {
        let confirmButtonTapped: Observable<Void>
        let addBookButtonTapped: Observable<Void>
        let deleteBookTapped: Observable<Int> // ✅ IndexPath.row 대신 Int(인덱스) 사용
    }

    struct Output {
        let navigateToBookList: Observable<Void>
        let showTitleInputPopup: Observable<Void>
        let bookList: Observable<[String]>
    }

    let disposeBag = DisposeBag()

    // MARK: Internal (변경됨)

    let bookListRelay = BehaviorRelay<[String]>(value: []) // ✅ 접근 수준 변경 (internal)
    let navigateToBookListRelay = PublishRelay<Void>()
    let showTitleInputPopupRelay = PublishRelay<Void>()

    func transform(_ input: Input) -> Output {
        input.confirmButtonTapped
            .bind(to: navigateToBookListRelay)
            .disposed(by: disposeBag)

        input.addBookButtonTapped
            .bind(to: showTitleInputPopupRelay)
            .disposed(by: disposeBag)

        input.deleteBookTapped
            .withLatestFrom(bookListRelay) { index, bookList -> [String] in
                var newList = bookList
                if index < newList.count { // ✅ 안전한 삭제를 위해 체크 추가
                    newList.remove(at: index)
                }
                return newList
            }
            .bind(to: bookListRelay)
            .disposed(by: disposeBag)

        return Output(
            navigateToBookList: navigateToBookListRelay.asObservable(),
            showTitleInputPopup: showTitleInputPopupRelay.asObservable(),
            bookList: bookListRelay.asObservable()
        )
    }

    func addBook(_ bookTitle: String) {
        var currentList = bookListRelay.value
        if !currentList.contains(bookTitle) { // ✅ 중복 방지 로직 추가
            currentList.append(bookTitle)
            bookListRelay.accept(currentList)
        }
    }
}
