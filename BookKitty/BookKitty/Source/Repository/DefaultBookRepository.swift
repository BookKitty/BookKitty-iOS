//
//  DefaultBookRepository.swift
//  BookKitty
//
//  Created by 권승용 on 1/23/25.
//

/// Book 모델을 가져오는 레포지토리
final class DefaultBookRepository: BookRepository {
    private let bookPersistence: BookCoreDataManageable

    init(bookPersistence: BookCoreDataManageable) {
        self.bookPersistence = bookPersistence
    }

    func fetchBookList() {}

    func fetchBookDetail() {}

    func saveBookList() {}

    func deleteBook() {}
}
