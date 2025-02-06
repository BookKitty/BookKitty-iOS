//
//  QuestionAnswerCoreDataManager.swift
//  BookKitty
//
//  Created by 임성수 on 1/23/25.
//

import CoreData

/// QuestionAnswer 엔티티를 관리하는 객체
final class QuestionAnswerCoreDataManager: QuestionAnswerCoreDataManageable {
    func modelToEntity(model _: QuestionAnswer) -> QuestionAnswerEntity? {
        nil
    }

    func entityToModel(entity _: QuestionAnswerEntity) -> QuestionAnswer? {
        nil
    }

    func create() {}

    func read() {}
}
