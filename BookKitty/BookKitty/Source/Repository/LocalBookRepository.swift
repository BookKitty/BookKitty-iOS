//
//  LocalBookRepository.swift
//  BookKitty
//
//  Created by 권승용 on 2/11/25.
//

import FirebaseAnalytics
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

    /// isbn에 해당하는 책의 상세정보 가져오기
    ///
    /// - Parameter isbn: 가져오고자 하는 책의 isbn 코드
    /// - Returns: Book 타입의 책 데이터
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

    /// 최근 추천받은 책목록 가져오기
    ///
    /// 질문답변을 통해 최근에 추천받은 책의 목록을 가져옵니다.
    /// - Returns: Book 모델의 배열
    func fetchRecentRecommendedBooks() -> [Book] {
        let linkEntities = bookQALinkCoreDataManager.selectRecentRecommendedBooks(
            context:
            context
        )
        var books: [Book] = []

        for linkEntity in linkEntities {
            if let bookEntity = linkEntity.book,
               let book = bookCoreDataManager.entityToModel(entity: bookEntity) {
                if !books.contains(book) {
                    books.append(book)
                }
            }
            if books.count == 5 {
                break
            }
        }

        BookKittyLogger.log("최근 추천된 책 불러오기 성공")
        return books
    }

    /// 여러 권의 책 저장
    /// 이미 코어데이터에 저장된 책은 제외하고 저장
    ///
    /// - Parameter data: Book 타입 데이터의 배열
    /// - Returns: 성공 여부 Bool 반환.
    func saveBookList(data: [Book]) -> Bool {
        do {
            let filteredBooks = data.filter {
                if bookCoreDataManager.selectBookByIsbn(isbn: $0.isbn, context: context) != nil {
                    BookKittyLogger.log("\($0.title) 책은 이미 저장되어 있으므로, 저장할 책 목록에서 제외합니다.")
                    return false
                }
                return true
            }

            let bookEntities = bookCoreDataManager.createMultipleBooksWithoutSave(
                data: filteredBooks,
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

    /// 단일 책 저장
    /// 이미 코어데이터에 저장된 책은 저장되지 않습니다.
    ///
    /// - Parameter data: Book 타입 데이터
    /// - Returns: 성공 여부 Bool 반환.
    func saveBook(book: Book) -> Bool {
        if bookCoreDataManager.selectBookByIsbn(isbn: book.isbn, context: context) != nil {
            BookKittyLogger.log("\(book.title) 책은 이미 저장되어 있습니다.")
            return false
        }

        return bookCoreDataManager.insertBook(model: book, context: context)
    }

    /// 나의 책장에 책 추가하기
    /// 이미 저장되어 있는 책을 소유 상태로 만들어 나의 책장에서 볼 수 있도록 합니다.
    ///
    /// - Parameter isbn: 책장에 등록하고자 하는 책의 isbn
    /// - Returns: 성공 여부 boolean 반환
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

    /// 나의 책장에서 책 제외하기
    /// 이미 저장되어 있는 책을 미소유 상태로 만들어 나의 책장에서 볼 수 없도록 합니다.
    ///
    /// - Parameter isbn: 책장에서 제외하고자 하는 책의 isbn
    /// - Returns: 성공 여부 boolean 반환
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

extension LocalBookRepository {
    func recodeOwnedBooksCount() {
        let count = bookCoreDataManager.readOwnedBooksCount(context: context)

        Analytics.logEvent("user_owned_book_count", parameters: [
            "count": count,
        ])
    }
}
