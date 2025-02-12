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
    // MARK: - Nested Types

    struct Input {
        let addBookWithTitleTapTrigger: Observable<String>
        let deleteBookTapTrigger: Observable<Int>
        let confirmButtonTapTrigger: Observable<Void>
        let leftBarButtonTapTrigger: Observable<Void>
    }

    struct Output {
        let addedBookList: Observable<[Book]>
    }

    // MARK: - Properties

    let disposeBag = DisposeBag()

    let navigateToBookListRelay = PublishRelay<Void>()
    let navigateBackRelay = PublishRelay<Void>()

    // MARK: - Private

    private let addedBookListRelay = BehaviorRelay<[Book]>(value: [])
    private var addedBookTitles = Set<String>() // ✅ 중복 방지용 Set

    // MARK: - Lifecycle

    init(initialBookList: [Book] = []) {
        addedBookListRelay.accept(initialBookList)
        addedBookTitles = Set(initialBookList.map(\.title)) // ✅ 초기 데이터 반영
    }

    // MARK: - Functions

    func transform(_ input: Input) -> Output {
        input.confirmButtonTapTrigger
            .bind(to: navigateToBookListRelay)
            .disposed(by: disposeBag)

        input.addBookWithTitleTapTrigger
            .subscribe(onNext: { [weak self] title in
                self?.appendBook(with: title)
            })
            .disposed(by: disposeBag)

        input.deleteBookTapTrigger
            .withLatestFrom(addedBookListRelay) { index, bookList in
                var newList = bookList
                if index < newList.count {
                    let removedTitle = newList[index].title
                    self.addedBookTitles.remove(removedTitle)
                    newList.remove(at: index)
                }

                return newList
            }
            .bind(to: addedBookListRelay)
            .disposed(by: disposeBag)

        return Output(addedBookList: addedBookListRelay.asObservable())
    }

    /// ✅ 새로운 책 추가 (Book 객체로)
    func appendBook(_ book: Book) {
        guard !addedBookTitles.contains(book.title) else {
            return
        } // ✅ 중복 방지
        addedBookTitles.insert(book.title)

        var currentList = addedBookListRelay.value
        currentList.append(book)
        addedBookListRelay.accept(currentList)
    }

    // MARK: - Private Methods

    private func appendBook(with title: String) {
        guard !addedBookTitles.contains(title) else {
            return
        }
        addedBookTitles.insert(title)

        let newBook = Book(
            isbn: UUID().uuidString,
            title: title,
            author: "미상",
            publisher: "미상",
            thumbnailUrl: nil
        )

        var currentList = addedBookListRelay.value
        currentList.append(newBook)
        addedBookListRelay.accept(currentList)
    }
}
