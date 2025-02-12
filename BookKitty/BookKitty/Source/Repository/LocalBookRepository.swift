//
//  LocalBookRepository.swift
//  BookKitty
//
//  Created by 권승용 on 2/11/25.
//

import Foundation
import RxSwift

struct LocalBookRepository: BookRepository {
    // MARK: - Properties

    // MARK: - Private

    private let context = CoreDataStack.shared.context
    private let bookCoreDataManager: BookCoreDataManageable
    private let bookQALinkCoreDataManager: BookQALinkCoreDataManageable

    // MARK: - Lifecycle

    init(
        bookCoreDataManager: BookCoreDataManageable = BookCoreDataManager(),
        bookQALinkCoreDataManager: BookQALinkCoreDataManageable = BookQALinkCoreDataManager()
    ) {
        self.bookCoreDataManager = bookCoreDataManager
        self.bookQALinkCoreDataManager = bookQALinkCoreDataManager
    }

    // MARK: - Functions

    // MARK: - Internal

    /// 페이지네이션이 적용된 책장 책 목록 가져오기
    /// 소유한 책만 가져옵니다.
    ///
    /// - Parameters:
    ///   - offset: 가져오기 시작하는 지점
    ///   - limit: 가져오는 개수
    /// - Returns: Book 모델의 배열
    func fetchBookList(offset: Int, limit: Int) -> [Book] {
        let bookEntities = bookCoreDataManager.selectOwnedBooks(
            offset: offset,
            limit: limit,
            context: context
        )

        if bookEntities.isEmpty {
            return []
        }

        return bookEntities.compactMap { bookCoreDataManager.entityToModel(entity: $0) }
    }

    func fetchBookDetail(by isbn: String) -> Book? {
        if let bookEntity = bookCoreDataManager.selectBookByIsbn(isbn: isbn, context: context) {
            return bookCoreDataManager.entityToModel(entity: bookEntity)
        }
        return nil
    }

    /// 주어진 isbn들에 대한 Book 모델 가져오기
    ///
    /// - Parameter : isbn 문자열의 배열.
    /// - Returns: Book 모델의 배열
    func fetchBookDetailFromISBNs(isbnList: [String]) -> [Book] {
        guard !isbnList.isEmpty else {
            return []
        }

        let bookEntities = bookCoreDataManager.selectBooksWithIsbnArray(
            isbnList: isbnList,
            context: context
        )
        BookKittyLogger.log("ISBN 배열로부터 책 가져오기 성공")
        return bookEntities.compactMap { bookCoreDataManager.entityToModel(entity: $0) }
    }

    func fetchRecentRecommendedBooks() -> [Book] {
        let linkEntities = bookQALinkCoreDataManager.selectRecentRecommendedBooks(context: context)
        var books: [Book] = []

        for linkEntity in linkEntities {
            if let bookEntity = linkEntity.book,
               let book = bookCoreDataManager.entityToModel(entity: bookEntity) {
                books.append(book)
            }
        }
        BookKittyLogger.log("최근 추천된 책 불러오기 성공")
        return books
    }

    func saveBookList(data: [Book]) -> Bool {
        do {
            let bookEntities = bookCoreDataManager.createMultipleBooksWithoutSave(
                data: data,
                context: context
            )
            guard bookEntities.count == data.count else {
                BookKittyLogger.log("반환 전후 갯수 다름;")
                return false
            }

            try context.save()
            BookKittyLogger.log("책 저장 성공")
            return true
        } catch {
            BookKittyLogger.log("책 저장 실패: \(error.localizedDescription)")
            return false
        }
    }

    func saveBook(book: Book) -> Bool {
        bookCoreDataManager.insertBook(model: book, context: context)
    }

    func addBookToShelf(isbn: String) -> Bool {
        do {
            if let book = bookCoreDataManager.selectBookByIsbn(isbn: isbn, context: context) {
                book.isOwned = true
                book.updatedAt = Date()
            }
            try context.save()
            BookKittyLogger.log("책장에 책 등록 성공")
            return true
        } catch {
            BookKittyLogger.log("책장에 책 등록 실패: \(error.localizedDescription)")
            return false
        }
    }

    func exceptBookFromShelf(isbn: String) -> Bool {
        do {
            if let book = bookCoreDataManager.selectBookByIsbn(isbn: isbn, context: context) {
                book.isOwned = false
                book.updatedAt = Date()
            }
            try context.save()
            BookKittyLogger.log("책장에 책 제거 성공")
            return true
        } catch {
            BookKittyLogger.log("책장에 책 제거 실패: \(error.localizedDescription)")
            return false
        }
    }
}
