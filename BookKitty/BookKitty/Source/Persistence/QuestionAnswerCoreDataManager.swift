//
//  QuestionAnswerCoreDataManager.swift
//  BookKitty
//
//  Created by 임성수 on 1/23/25.
//

import CoreData

/// QuestionAnswer 엔티티를 관리하는 코어 데이터 매니저 기능을 추상화하는 프로토콜
protocol QuestionAnswerCoreDataManageable {
    // 내부 요구사항은 추후 변경됩니다
    func create()
    func read()
    func delete()
    func modelToEntity(model: QuestionAnswer) -> QuestionAnswerEntity?
    func entityToModel(entity: QuestionAnswerEntity) -> QuestionAnswer?
}

/// QuestionAnswer 엔티티를 관리하는 객체
final class QuestionAnswerCoreDataManager: QuestionAnswerCoreDataManageable {
    private func modelToEntityWithoutBooks(model: QuestionAnswer) -> QuestionAnswerEntity? {
        nil
    }

    func entityToModel(entity _: QuestionAnswerEntity) -> QuestionAnswer? {
        nil
    }

    func create() {}

    func read() {}

    func delete() {}
}
