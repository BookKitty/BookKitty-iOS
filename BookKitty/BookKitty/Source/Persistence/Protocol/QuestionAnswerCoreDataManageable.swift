//
//  QuestionAnswerCoreDataManageable.swift
//  BookKitty
//
//  Created by 권승용 on 2/11/25.
//

import CoreData

/// QuestionAnswer 엔티티를 관리하는 코어 데이터 매니저 기능을 추상화하는 프로토콜
protocol QuestionAnswerCoreDataManageable {
    func selectQuestionHistories(offset: Int, limit: Int, context: NSManagedObjectContext)
        -> [QuestionAnswerEntity]
    func selectById(by uuid: UUID, context: NSManagedObjectContext) -> QuestionAnswerEntity?
    func deleteQuestionAnswer(by id: UUID, context: NSManagedObjectContext) -> Bool
}
