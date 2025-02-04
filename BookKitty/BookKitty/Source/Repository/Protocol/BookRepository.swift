//
//  BookRepository.swift
//  BookKitty
//
//  Created by 권승용 on 1/23/25.
//

/// 로컬에 저장된 책 정보에 대한 레포지토리 기능을 나타냅니다.
protocol BookRepository {
    // 요구사항은 추후 변경됩니다
    func fetchBookList(offset: Int, limit: Int) -> [Book]
    func fetchBookDetail() -> Book
    func fetchBookDetailFromISBNs(_ isbnList: [String]) -> [Book]
    func saveBookList()
    func deleteBook()
}
