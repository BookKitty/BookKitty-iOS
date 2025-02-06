//
//  BookQALinkCoreDataManager.swift
//  BookKitty
//
//  Created by 임성수 on 2/6/25.
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
}

/// BookQuestionAnswerLink 엔티티를 관리하는 객체
final class BookQALinkCoreDataManager: BookQALinkCoreDataManageable {
    /// 최근 추천받은 책을 가져오기
    /// - Parameter context: 코어데이터 컨텍스트
    /// - Returns: 가장 최근에 생성된 BookQuestionAnswerLinkEntity
    func selectRecentRecommendedBooks(context: NSManagedObjectContext)
        -> [BookQuestionAnswerLinkEntity] {
        let fetchRequest: NSFetchRequest<BookQuestionAnswerLinkEntity> =
            BookQuestionAnswerLinkEntity.fetchRequest()

        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        fetchRequest.fetchLimit = 5

        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("최근 추천책 조회 실패: \(error.localizedDescription)")
            return []
        }
    }

    /// <#Description#>
    /// - Parameters:
    ///   - bookEntity: <#bookEntity description#>
    ///   - questionAnswerEntity: <#questionAnswerEntity description#>
    ///   - context: <#context description#>
    /// - Returns: <#description#>
    func createNewLinkWithoutSave(
        bookEntity: BookEntity,
        questionAnswerEntity: QuestionAnswerEntity,
        context: NSManagedObjectContext
    ) -> BookQuestionAnswerLinkEntity {
        let linkEntity = BookQuestionAnswerLinkEntity(context: context)
        linkEntity.book = bookEntity
        linkEntity.questionAnswer = questionAnswerEntity
        linkEntity.createdAt = Date()

        return linkEntity
    }
}
