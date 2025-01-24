//
//  AddBookService.swift
//  BookKitty
//
//  Created by 권승용 on 1/23/25.
//

import Foundation

/// 책 추가 작업을 관리하는 서비스 클래스입니다.
/// 이 클래스는 `AddBookServiceable` 프로토콜을 구현하며
/// 시스템에 새로운 책을 추가하는 비즈니스 로직을 처리합니다.
final class AddBookService: AddBookServiceable {
    // MARK: Lifecycle

    /// AddBookService의 새 인스턴스를 초기화합니다.
    /// - Parameter bookRepository: 책 데이터 작업을 처리할 저장소입니다.
    init(bookRepository: BookRepository) {
        self.bookRepository = bookRepository
    }

    // MARK: Internal

    /// 시스템에 새로운 책을 추가합니다.
    /// - Note: 이 메서드는 현재 비어있으며 구현이 필요합니다.
    func addBook() {}

    // MARK: Private

    /// 책 관련 데이터 작업을 처리하는 저장소입니다.
    private let bookRepository: BookRepository
}
