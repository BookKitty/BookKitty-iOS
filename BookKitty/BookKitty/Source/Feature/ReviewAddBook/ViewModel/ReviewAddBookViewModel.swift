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

    // MARK: - Init

    init(initialBookList: [Book] = []) {
        bookListRelay.accept(initialBookList)
        addedBookTitles = Set(initialBookList.map(\.title)) // ✅ 초기 데이터 반영
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

    /// ✅ 네비게이션 이벤트
    let navigateToBookListRelay = PublishRelay<Void>()

    func transform(_ input: Input) -> Output {
        input.confirmButtonTapped
            .bind(to: navigateToBookListRelay)
            .disposed(by: disposeBag)

        input.addBookWithTitleTapped
            .subscribe(onNext: { [weak self] title in
                self?.appendBook(with: title)
            })
            .disposed(by: disposeBag)

        input.deleteBookTapped
            .withLatestFrom(bookListRelay) { index, bookList -> [Book] in
                var newList = bookList
                if index < newList.count {
                    let removedTitle = newList[index].title
                    self.addedBookTitles.remove(removedTitle) // ✅ 삭제된 책 제목 제거
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

    /// ✅ 새로운 책 추가 메서드
    func appendBook(with title: String) {
        guard !addedBookTitles.contains(title) else {
            return
        } // ✅ 중복 방지
        addedBookTitles.insert(title)

        let newBook = Book(
            isbn: UUID().uuidString,
            title: title,
            author: "미상",
            publisher: "미상",
            thumbnailUrl: nil
        )

        var currentList = bookListRelay.value
        currentList.append(newBook)
        bookListRelay.accept(currentList)
    }

    /// ✅ `Book` 객체를 직접 추가하는 오버로드 메서드
    func appendBook(_ book: Book) {
        guard !addedBookTitles.contains(book.title) else {
            return
        } // ✅ 중복 방지
        addedBookTitles.insert(book.title)

        var currentList = bookListRelay.value
        currentList.append(book)
        bookListRelay.accept(currentList)
    }

    // MARK: Private

    private let bookListRelay = BehaviorRelay<[Book]>(value: [])
    private var addedBookTitles = Set<String>() // ✅ 중복 방지용 Set
}
