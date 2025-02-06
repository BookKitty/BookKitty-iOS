//
//  MockBookRepository.swift
//  BookKitty
//
//  Created by 권승용 on 1/23/25.
//

import Foundation

/// 테스트를 위한 가짜 레포지토리
final class MockBookRepository: BookRepository {
    
    let mockBookList = [
        Book(
            isbn: "978-3-16-148410-0",
            title: "Swift Programming Basics",
            author: "John Doe",
            publisher: "Tech Press",
            thumbnailUrl: URL(string: "https://picsum.photos/200/300")
        ),
        Book(
            isbn: "978-1-23-456789-7",
            title: "Mastering iOS Development",
            author: "Jane Smith",
            publisher: "Code Masters",
            thumbnailUrl: URL(string: "https://picsum.photos/200/300")
        ),
        Book(
            isbn: "978-0-12-345678-9",
            title: "The Art of Clean Code",
            author: "Robert C. Martin",
            publisher: "Pragmatic Bookshelf",
            thumbnailUrl: URL(string: "https://picsum.photos/200/300")
        ),
        Book(
            isbn: "978-9-87-654321-0",
            title: "Data Structures & Algorithms",
            author: "Alice Johnson",
            publisher: "Algo Press",
            thumbnailUrl: URL(string: "https://picsum.photos/200/300")
        ),
    ]

    let mockBookDetail = Book(
        isbn: "978-9-87-654321-0",
        title: "Data Structures & Algorithms",
        author: "Alice Johnson",
        publisher: "Algo Press",
        thumbnailUrl: URL(string: "https://picsum.photos/200/300")
    )

    // 아래 함수는 실제로 레포지토리에서 구현되지 않았습니다.
    // fetchBookList 함수를 사용해 주세요.
    func fetchAllBooks() -> [Book] {
        [
            Book(
                isbn: "978-3-16-148410-0",
                title: "Swift Programming Basics",
                author: "John Doe",
                publisher: "Tech Press",
                thumbnailUrl: URL(string: "https://picsum.photos/200/300")
            ),
            Book(
                isbn: "978-3-16-148410-0",
                title: "Swift Programming Basics",
                author: "John Doe",
                publisher: "Tech Press",
                thumbnailUrl: URL(string: "https://picsum.photos/200/300")
            ),
            Book(
                isbn: "978-3-16-148410-0",
                title: "Swift Programming Basics",
                author: "John Doe",
                publisher: "Tech Press",
                thumbnailUrl: URL(string: "https://picsum.photos/200/300")
            ),
        ]
    }
    
    func fetchBookList(offset: Int, limit: Int) -> [Book] {
        mockBookList
    }
    
    func fetchBookDetail(by isbn: String) -> Book? {
        mockBookDetail
    }
    
    func fetchBookDetailFromISBNs(isbnList: [String]) -> [Book] {
        mockBookList
    }
    
    func fetchRecentRecommendedBooks() -> [Book] {
        mockBookList
    }
    
    func saveBookList(data: [Book]) -> Bool {
        return true
    }
    
    func saveBook(book: Book) -> Bool {
        return true
    }
    
    func addBookToShelf(isbn: String) -> Bool {
        return true
    }
    
    func exceptBookFromShelf(isbn: String) -> Bool {
        return true
    }

    // MARK: Private
}
