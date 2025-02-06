//
//  BookRepository.swift
//  BookKitty
//
//  Created by 권승용 on 1/23/25.
//

/// 로컬에 저장된 책 정보에 대한 레포지토리 기능을 나타냅니다.
protocol BookRepository {
    // 요구사항은 추후 변경됩니다
    func fetchBookList(offset: Int, limit: Int) -> [Book] // 책목록 화면에서 목록 가져오기
    func fetchBookDetail(by isbn: String) -> Book? // isbn으로 일치하는 책 한권 가져오기
    func fetchBookDetailFromISBNs(_ isbnList: [String]) -> [Book]
    func fetchRecentRecommendedBooks() -> [Book] // 홈화면에서 최근 추천받은 책 목록

    func saveBookList(data: [Book]) -> Bool // 저장 프로세스 결과를 전달.

    func addBookToShelf(isbn: String) -> Bool // 나의 책장에 책 추가하기(책 상세페이지에서 미소유
    func deleteBookFromShelf(isbn: String) -> Bool // 나의 책장에서 책 제거하기
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

    func fetchBookList(offset _: Int, limit _: Int) -> [Book] {
        []
    }

    func fetchBookDetail(by _: String) -> Book? {
        nil
    }

    func fetchBookDetailFromISBNs(_: [String]) -> [Book] {
        []
    }

    func fetchRecentRecommendedBooks() -> [Book] {
        []
    }

    func saveBookList(data _: [Book]) -> Bool {
        false
    }

    func addBookToShelf(isbn _: String) -> Bool {
        false
    }

    func deleteBookFromShelf(isbn _: String) -> Bool {
        false
    }

    // MARK: Private

    private let context = CoreDataStack.shared.context
    private let bookCoreDataManager: BookCoreDataManageable
    private let bookQALinkCoreDataManager: BookQALinkCoreDataManageable
}
