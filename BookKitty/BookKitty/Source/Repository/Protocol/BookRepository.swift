//
//  BookRepository.swift
//  BookKitty
//
//  Created by 권승용 on 1/23/25.
//

import Foundation


/// 로컬에 저장된 책 정보에 대한 레포지토리 기능을 나타냅니다.
protocol BookRepository {
    // 요구사항은 추후 변경됩니다
    func fetchBookList(offset: Int, limit: Int) -> [Book] // 책목록 화면에서 목록 가져오기
    func fetchBookDetail(by isbn: String) -> Book? // isbn으로 일치하는 책 한권 가져오기
    func fetchBookDetailFromISBNs(isbnList: [String]) -> [Book]
    func fetchRecentRecommendedBooks() -> [Book] // 홈화면에서 최근 추천받은 책 목록

    func saveBookList(data: [Book]) -> Bool // 저장 프로세스 결과를 전달.
    func saveBook(book: Book) -> Bool // 저장 프로세스 결과를 전달.

    func addBookToShelf(isbn: String) -> Bool // 나의 책장에 책 추가하기(책 상세페이지에서 미소유
    func exceptBookFromShelf(isbn: String) -> Bool // 나의 책장에서 책 제외하기
}

struct LocalBookRepository: BookRepository {
    // MARK: Lifecycle

    init(
        bookCoreDataManager: BookCoreDataManageable = BookCoreDataManager(),
        bookQALinkCoreDataManager: BookQALinkCoreDataManageable = BookQALinkCoreDataManager()
    ) {
        self.bookCoreDataManager = bookCoreDataManager
        self.bookQALinkCoreDataManager = bookQALinkCoreDataManager
    }

    // MARK: Internal

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
        guard !isbnList.isEmpty else { return [] }
        
        let bookEntities = bookCoreDataManager.selectBooksWithIsbnArray(isbnList: isbnList, context: context)
        return bookEntities.compactMap { bookCoreDataManager.entityToModel(entity: $0) }
    }

    func fetchRecentRecommendedBooks() -> [Book] {
        let linkEntities = bookQALinkCoreDataManager.selectRecentRecommendedBooks(context: context)
        var books: [Book] = []
        
        linkEntities.forEach {
            if let bookEntity = $0.book,
                let book = bookCoreDataManager.entityToModel(entity: bookEntity) {
                books.append(book)
            }
        }
        
        return books
    }

    func saveBookList(data: [Book]) -> Bool {
        do {
            let bookEntities = bookCoreDataManager.createMultipleBooksWithoutSave(
                data: data,
                context: context
            )
            guard bookEntities.count == data.count else {
                print("왜 변환 전과 후 데이터 개수가 다를까?")
                return false
            }

            try context.save()
            return true
        } catch {
            print("책 저장 실패: \(error.localizedDescription)")
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
            return true
        } catch {
            print("책 등록 실패: \(error.localizedDescription)")
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
            return true
        } catch {
            print("책 등록 실패: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: Private

    private let context = CoreDataStack.shared.context
    private let bookCoreDataManager: BookCoreDataManageable
    private let bookQALinkCoreDataManager: BookQALinkCoreDataManageable
}
