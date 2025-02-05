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

    init(initialBookList: [Book] = []) {
        bookListRelay.accept(initialBookList)
    }

    // MARK: Internal

    struct Input {
        let confirmButtonTapped: Observable<Void>
        let addBookWithTitleTapped: Observable<String>
        let deleteBookTapped: Observable<Int>
    }

    struct Output {
        let navigateToBookList: Observable<Void>
        let bookList: BehaviorRelay<[Book]>
    }

    let disposeBag = DisposeBag()

    /// ✅ 접근 제어를 internal로 변경 (private -> internal)
    let navigateToBookListRelay = PublishRelay<Void>()

    func transform(_ input: Input) -> Output {
        input.confirmButtonTapped
            .bind(to: navigateToBookListRelay)
            .disposed(by: disposeBag)

        input.addBookWithTitleTapped
            .withLatestFrom(bookListRelay) { newTitle, bookList -> [Book] in
                var newList = bookList
                let newBook = Book(
                    isbn: UUID().uuidString,
                    title: newTitle,
                    author: "미상",
                    publisher: "미상",
                    thumbnailUrl: nil
                )
                if !newList.contains(where: { $0.title == newTitle }) {
                    newList.append(newBook)
                }
                return newList
            }
            .bind(to: bookListRelay)
            .disposed(by: disposeBag)

        input.deleteBookTapped
            .withLatestFrom(bookListRelay) { index, bookList -> [Book] in
                var newList = bookList
                if index < newList.count {
                    newList.remove(at: index)
                }
                return newList
            }
            .bind(to: bookListRelay)
            .disposed(by: disposeBag)

        return Output(
            navigateToBookList: navigateToBookListRelay.asObservable(),
            bookList: bookListRelay
        )
    }

    // MARK: Private

    private let bookListRelay = BehaviorRelay<[Book]>(value: [])
}
