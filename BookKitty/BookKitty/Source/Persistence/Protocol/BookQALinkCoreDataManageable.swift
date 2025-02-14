//
//  BookQALinkCoreDataManageable.swift
//  BookKitty
//
//  Created by 권승용 on 2/11/25.
//

import CoreData

/// BookQuestionAnswerLink 엔티티를 관리하는 코어 데이터 매니저 기능을 추상화하는 프로토콜
protocol BookQALinkCoreDataManageable {
    func selectRecentRecommendedBooks(context: NSManagedObjectContext)
        -> [BookQuestionAnswerLinkEntity]

    func createNewLinkWithoutSave(
        bookEntity: BookEntity,
        questionAnswerEntity: QuestionAnswerEntity,
        context: NSManagedObjectContext
    ) -> BookQuestionAnswerLinkEntity

    func selectLinkedBooksByQuestionId(questionId: UUID, context: NSManagedObjectContext)
        -> [BookEntity]
}
