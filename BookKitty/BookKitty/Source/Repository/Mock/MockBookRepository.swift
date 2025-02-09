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
            isbn: "9788950963262",
            title: "침묵의 기술",
            author: "조제프 앙투안 투생 디누아르",
            publisher: "아르테(arte)",
            thumbnailUrl: URL(
                string: "https://shopping-phinf.pstatic.net/main_3249696/32496966995.20240321071044.jpg"
            )
        ),
        Book(
            isbn: "9788954625760",
            title: "불안의 책",
            author: "페르난두 페소아",
            publisher: "문학동네",
            thumbnailUrl: URL(
                string: "https://shopping-phinf.pstatic.net/main_3245596/32455964233.20230822103854.jpg"
            )
        ),
        Book(
            isbn: "9788981171353",
            title: "마음챙김 명상",
            author: "존 카밧진",
            publisher: "사람과책",
            thumbnailUrl: URL(
                string: "https://shopping-phinf.pstatic.net/main_3245593/32455931661.20220527022757.jpg"
            )
        ),
        Book(
            isbn: "9791196914806",
            title: "당신 인생의 이야기",
            author: "테드 창",
            publisher: "엘리",
            thumbnailUrl: URL(
                string: "https://shopping-phinf.pstatic.net/main_3248052/32480522779.20231230070743.jpg"
            )
        ),
    ]

    /// 아래 함수는 실제로 레포지토리에서 구현되지 않았습니다.
    /// fetchBookList 함수를 사용해 주세요.
    func fetchAllBooks() -> [Book] {
        [
            Book(
                isbn: "9788950963262",
                title: "침묵의 기술",
                author: "조제프 앙투안 투생 디누아르",
                publisher: "아르테(arte)",
                thumbnailUrl: URL(
                    string: "https://shopping-phinf.pstatic.net/main_3249696/32496966995.20240321071044.jpg"
                )
            ),
            Book(
                isbn: "9788954625760",
                title: "불안의 책",
                author: "페르난두 페소아",
                publisher: "문학동네",
                thumbnailUrl: URL(
                    string: "https://shopping-phinf.pstatic.net/main_3245596/32455964233.20230822103854.jpg"
                )
            ),
            Book(
                isbn: "9788981171353",
                title: "마음챙김 명상",
                author: "존 카밧진",
                publisher: "사람과책",
                thumbnailUrl: URL(
                    string: "https://shopping-phinf.pstatic.net/main_3245593/32455931661.20220527022757.jpg"
                )
            ),
            Book(
                isbn: "9791196914806",
                title: "당신 인생의 이야기",
                author: "테드 창",
                publisher: "엘리",
                thumbnailUrl: URL(
                    string: "https://shopping-phinf.pstatic.net/main_3248052/32480522779.20231230070743.jpg"
                )
            ),
        ]
    }

    func fetchBookList(offset _: Int, limit _: Int) -> [Book] {
        mockBookList
    }

    func fetchBookDetail(by _: String) -> Book? {
        mockBookList[0]
    }

    func fetchBookDetailFromISBNs(isbnList _: [String]) -> [Book] {
        mockBookList
    }

    func fetchRecentRecommendedBooks() -> [Book] {
        mockBookList
    }

    func saveBookList(data _: [Book]) -> Bool {
        true
    }

    func saveBook(book _: Book) -> Bool {
        true
    }

    func addBookToShelf(isbn _: String) -> Bool {
        true
    }

    func exceptBookFromShelf(isbn _: String) -> Bool {
        true
    }
}
