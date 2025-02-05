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

    init(initialBookList: [Book]) {
        bookListRelay.accept(initialBookList)
    }

    // MARK: Internal

    struct Input {
        let confirmButtonTapped: Observable<Void>
        let addBookWithTitleTapped: Observable<String> // ✅ 직접 입력한 제목을 받도록 수정
        let deleteBookTapped: Observable<Int> // ✅ IndexPath.row 대신 Int(인덱스) 사용
    }

    struct Output {
        let navigateToBookList: Observable<Void>
        let bookList: Observable<[Book]>
    }

    let disposeBag = DisposeBag()

    let navigateToBookListRelay = PublishRelay<Void>()

    func transform(_ input: Input) -> Output {
        input.confirmButtonTapped
            .bind(to: navigateToBookListRelay)
            .disposed(by: disposeBag)

        input.addBookWithTitleTapped
            .withLatestFrom(bookListRelay) { newTitle, bookList -> [Book] in
                var newList = bookList
                let newBook = Book(
                    isbn: UUID().uuidString, // ✅ 임시 ISBN 값 생성
                    title: newTitle,
                    author: "미상",
                    publisher: "미상",
                    thumbnailUrl: nil
                )
                if !newList.contains(newBook) { // ✅ 중복 방지
                    newList.append(newBook)
                }
                return newList
            }
            .bind(to: bookListRelay)
            .disposed(by: disposeBag)

        input.deleteBookTapped
            .withLatestFrom(bookListRelay) { index, bookList -> [Book] in
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
            bookList: bookListRelay.asObservable()
        )
    }

    // MARK: Private

    // MARK: Internal (변경됨)

    private let bookListRelay = BehaviorRelay<[Book]>(value: []) // ✅ Book 타입으로 변경
}
