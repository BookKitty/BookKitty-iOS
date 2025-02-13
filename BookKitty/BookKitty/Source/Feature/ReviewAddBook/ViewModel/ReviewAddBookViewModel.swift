//
//  ReviewAddBookViewModel.swift
//  BookKitty
//
//  Created by 반성준 on 1/31/25.
//

import BookMatchKit
import Foundation
import RxCocoa
import RxSwift
import UIKit // ✅ UIImage 오류 해결

final class ReviewAddBookViewModel: ViewModelType {
    // MARK: - Nested Types

    struct Input {
        let addBookWithTitleTapTrigger: Observable<String>
        let deleteBookTapTrigger: Observable<Int>
        let confirmButtonTapTrigger: Observable<Void>
        let leftBarButtonTapTrigger: Observable<Void>
        let capturedImage: Observable<UIImage> // ✅ 사진 캡처 후 OCR로 책 추가
    }

    struct Output {
        let addedBookList: Observable<[Book]>
        let error: Observable<Error> // ✅ 오류 출력 스트림
    }

    // MARK: - Properties

    let disposeBag = DisposeBag()

    let navigateToBookListRelay = PublishRelay<Void>()
    let navigateBackRelay = PublishRelay<Void>()

    // MARK: - Private

    private let addedBookListRelay = BehaviorRelay<[Book]>(value: [])
    private let errorRelay = PublishRelay<Error>() // ✅ 오류 처리 스트림
    private var addedBookTitles = Set<String>() // ✅ 중복 방지용 Set

    private let bookMatchKit: BookMatchKit?

    // MARK: - Lifecycle

    init(initialBookList: [Book] = [], bookMatchKit: BookMatchKit) {
        self.bookMatchKit = bookMatchKit
        addedBookListRelay.accept(initialBookList)
        addedBookTitles = Set(initialBookList.map(\.title)) // ✅ 초기 데이터 반영
    }

    // MARK: - Functions

    func transform(_ input: Input) -> Output {
        // ✅ "완료 버튼" 클릭 시, 책 리스트 화면으로 이동
        input.confirmButtonTapTrigger
            .bind(to: navigateToBookListRelay)
            .disposed(by: disposeBag)

        // ✅ OCR을 활용해 책 자동 추가
        input.capturedImage
            .flatMapLatest { [weak self] image -> Observable<Book?> in
                guard let self else {
                    return .empty()
                }

                print("📸 OCR 시작...")
                return bookMatchKit!.matchBook(image: image)
                    .map { bookItem -> Book? in // ✅ BookItem → Book 변환
                        guard let bookItem else {
                            return nil
                        }
                        return Book(
                            isbn: bookItem.isbn,
                            title: bookItem.title,
                            author: bookItem.author,
                            publisher: bookItem.publisher,
                            thumbnailUrl: URL(string: bookItem.image)
                        )
                    }
                    .do(onSuccess: { book in
                        if let book {
                            print("📖 OCR 성공: \(book.title)")
                        } else {
                            print("⚠️ OCR 실패: 매칭된 책 없음")
                        }
                    }, onError: { error in
                        print("❌ OCR 오류: \(error.localizedDescription)")
                    })
                    .asObservable()
                    .catch { error in
                        self.errorRelay.accept(error)
                        return .empty()
                    }
            }
            .compactMap { $0 } // nil 값 제거
            .subscribe(onNext: { [weak self] book in
                self?.appendBook(book)
            })
            .disposed(by: disposeBag)

        // ✅ 수동으로 책 제목 추가 (OCR 실패 시 사용)
        input.addBookWithTitleTapTrigger
            .subscribe(onNext: { [weak self] title in
                self?.appendBook(with: title)
            })
            .disposed(by: disposeBag)

        // ✅ 책 삭제 기능
        input.deleteBookTapTrigger
            .withLatestFrom(addedBookListRelay) { index, bookList -> [Book] in
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

        return Output(
            addedBookList: addedBookListRelay.asObservable(),
            error: errorRelay.asObservable()
        )
    }

    /// ✅ OCR 또는 수동 입력을 통해 새로운 책 추가
    func appendBook(_ book: Book) {
        guard !addedBookTitles.contains(book.title) else {
            print("⚠️ 중복 책 추가 시도: \(book.title)")
            return
        }
        addedBookTitles.insert(book.title)

        var currentList = addedBookListRelay.value
        currentList.append(book)
        addedBookListRelay.accept(currentList)
        print("✅ 책 추가 완료: \(book.title)")
    }

    // MARK: - Private Methods

    private func appendBook(with title: String) {
        guard !addedBookTitles.contains(title), !title.isEmpty else {
            print("⚠️ 빈 제목이거나 중복된 책 추가 시도")
            return
        }

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
        addedBookTitles.insert(title)
        print("✅ 수동 책 추가 완료: \(title)")
    }
}
