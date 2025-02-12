//
//  BookQALinkCoreDataManager.swift
//  BookKitty
//
//  Created by 임성수 on 2/6/25.
//

import CoreData

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
            let fetchresult = try context.fetch(fetchRequest)
            BookKittyLogger.log("최근 추천책 조회 성공")
            return fetchresult
        } catch {
            BookKittyLogger.log("최근 추천책 조회 실패: \(error.localizedDescription)")
            return []
        }
    }

    /// 새로운 `BookQuestionAnswerLinkEntity` 객체를 생성하지만 저장하지 않기
    /// - Parameters:
    ///   - bookEntity: 연결할 `BookEntity` 객체
    ///   - questionAnswerEntity: 연결할 `QuestionAnswerEntity` 객체
    ///   - context: `NSManagedObjectContext` 객체, 새 엔터티를 생성하는 데 사용됨
    func createNewLinkWithoutSave(
        bookEntity: BookEntity,
        questionAnswerEntity: QuestionAnswerEntity,
        context: NSManagedObjectContext
    ) {
        let linkEntity = BookQuestionAnswerLinkEntity(context: context)
        linkEntity.book = bookEntity
        linkEntity.questionAnswer = questionAnswerEntity
        linkEntity.createdAt = Date()

        BookKittyLogger.log("BookQuestionAnswerLinkEntity 생성 성공")
    }
}
