//
//  AddBookServiceable.swift
//  BookKitty
//
//  Created by 권승용 on 1/23/25.
//

/// 책 추가 기능을 제공하는 프로토콜
/// - 사용자가 새로운 책을 추가할 때 필요한 기능을 정의합니다.
/// - 이 프로토콜을 채택하는 클래스는 책 추가 로직을 구현해야 합니다.
protocol AddBookServiceable {
    /// 새로운 책을 추가하는 메서드
    /// - 사용자가 입력한 책 정보를 시스템에 저장합니다.
    func addBook()
}
