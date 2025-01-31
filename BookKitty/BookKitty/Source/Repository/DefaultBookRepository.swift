//
//  DefaultBookRepository.swift
//  BookKitty
//
//  Created by 권승용 on 1/23/25.
//

/// Book 모델을 가져오는 레포지토리
final class DefaultBookRepository: BookRepository {
    // MARK: Lifecycle

    init(bookPersistence: BookCoreDataManageable) {
        self.bookPersistence = bookPersistence
    }

    // MARK: Internal

    func fetchBookDetailFromISBNs(_: [String]) -> [Book] {
        []
    }

    func fetchBookList() {}

    func fetchBookDetail() {}

    func saveBookList() {}

    func deleteBook() {}

    // MARK: Private

    private let bookPersistence: BookCoreDataManageable
}
