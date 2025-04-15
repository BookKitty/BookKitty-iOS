//
//  BookQALinkCoreDataManager.swift
//  BookKitty
//
//  Created by 임성수 on 2/6/25.
//

import CoreData
import LogKit

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
        fetchRequest.fetchLimit = 20

        do {
            let fetchresult = try context.fetch(fetchRequest)
            LogKit.log("최근 추천책 조회 성공")
            return fetchresult
        } catch {
            LogKit.log("최근 추천책 조회 실패: \(error.localizedDescription)")
            return []
        }
    }

    /// 저장없이 새로운 링크 만들기
    /// - Parameters:
    ///   - bookEntity: 연결하고자 하는 책 엔티티
    ///   - questionAnswerEntity: 연결하고자 하는 질문 엔티티
    ///   - context: 코어데이터 컨텍스트
    /// - Returns: 링크 엔티티
    func createNewLinkWithoutSave(
        bookEntity: BookEntity,
        questionAnswerEntity: QuestionAnswerEntity,
        context: NSManagedObjectContext
    ) -> BookQuestionAnswerLinkEntity {
        let linkEntity = BookQuestionAnswerLinkEntity(context: context)
        linkEntity.book = bookEntity
        linkEntity.questionAnswer = questionAnswerEntity
        linkEntity.createdAt = Date()

        LogKit.log("BookQuestionAnswerLinkEntity 생성 성공")

        return linkEntity
    }

    /// 특정 질문에 연결된 책 엔티티 목록 가져오기
    /// - Parameters:
    ///   - questionId: 가져오고자 하는 대상 질문의 uuid
    ///   - context: 코어데이터 컨텍스트
    /// - Returns: 책 엔티티의 배열
    func selectLinkedBooksByQuestionId(
        questionId: UUID,
        context: NSManagedObjectContext
    ) -> [BookEntity] {
        do {
            let linkRequest: NSFetchRequest<BookQuestionAnswerLinkEntity> =
                BookQuestionAnswerLinkEntity
                    .fetchRequest()
            linkRequest.predicate = NSPredicate(
                format: "questionAnswer.id == %@",
                questionId as CVarArg
            )

            let linkedEntities = try context.fetch(linkRequest)

            // 각 링크 엔티티에서 `book`을 추출
            return linkedEntities.compactMap(\.book)
        } catch {
            LogKit.log("질문 ID에 연결된 책 조회 실패: \(error.localizedDescription)")
            return []
        }
    }
}
