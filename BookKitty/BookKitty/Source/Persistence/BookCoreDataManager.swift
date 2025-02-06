//
//  BookCoreDataManager.swift
//  BookKitty
//
//  Created by 권승용 on 1/23/25.
//

import CoreData

/// Book 엔티티를 관리하는 코어 데이터 매니저 기능을 추상화하는 프로토콜
protocol BookCoreDataManageable {
    // 내부 요구사항은 추후 변경됩니다
    func create(model: Book) -> Bool
    func read()
    func updateOwnedStatus(isbn: String) -> Bool
    func modelToEntity(model: Book) -> BookEntity?
    func entityToModel(entity: BookEntity) -> Book?
}

/// Book 엔티티를 관리하는 객체
final class BookCoreDataManager: BookCoreDataManageable {
    /// 새로운 Book 모델 데이터를 코어데이터의 BookEntity로 만들기
    /// - Parameter model : Book 모델
    /// - Returns: 옵셔널 BookEntity 타입 객체
    func modelToEntity(model _: Book) -> BookEntity? {
        nil
    }

    /// BookEntity 객체를 프레젠테이션 레이어의 Book 모델로 변경하기
    /// - Parameter entity: BookEntity 객체
    /// - Returns: 옵셔널 Book 모델 객체
    func entityToModel(entity _: BookEntity) -> Book? {
        nil
    }

    /// 새로운 Book Entity 객체를 저장하기
    /// - Parameter model: 저장하고자 하는 Book 모델 객체
    /// - Returns: 성공 여부를 Bool 타입으로 반환
    func create(model _: Book) -> Bool {
        false
    }

    func read() {}
    
    func delete() {}

    /// 책의 소유 여부를 변경
    /// - Parameter isbn: 변경하고자 하는 책의 isbn
    /// - Returns: 성공 여부를 Bool 타입으로 반환
    func updateOwnedStatus(isbn _: String) -> Bool {
        false
    }
}
