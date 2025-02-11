//
//  QuestionAnswerCoreDataManager.swift
//  BookKitty
//
//  Created by 임성수 on 1/23/25.
//

import CoreData

/// QuestionAnswer 엔티티를 관리하는 객체
final class QuestionAnswerCoreDataManager: QuestionAnswerCoreDataManageable {
    /// 이전 질문 목록 가져오기
    /// - Parameters:
    ///   - offset: 아이템을 가져오기 시작하는 지점
    ///   - limit: 한번에 가져오는 아이템의 최대 개수
    ///   - context: 코어데이터 컨텍스트
    /// - Returns: 조건을 충족하는 BookEntity 배열
    func selectQuestionHistories(
        offset: Int,
        limit: Int,
        context: NSManagedObjectContext
    ) -> [QuestionAnswerEntity] {
        let request: NSFetchRequest<QuestionAnswerEntity> = QuestionAnswerEntity.fetchRequest()
        request.fetchOffset = offset
        request.fetchLimit = limit

        // createdAt 내림차순 정렬 추가
        let sortDescriptor = NSSortDescriptor(key: "createdAt", ascending: false)
        request.sortDescriptors = [sortDescriptor]

        do {
            return try context.fetch(request)
        } catch {
            print("질문 목록 가져오기 실패: \(error.localizedDescription)")
            return []
        }
    }

    /// uuid에 해당하는 질문답변 데이터 가져오기
    /// - Parameters:
    ///   - id: 질문답변의 고유 uuid값
    ///   - context: 코어데이터 컨텍스트
    /// - Returns: 해당 uuid 값을 가지고 있는 QuestionBookEntity
    func selectById(by uuid: UUID, context: NSManagedObjectContext) -> QuestionAnswerEntity? {
        let request: NSFetchRequest<QuestionAnswerEntity> = QuestionAnswerEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)

        do {
            if let entity = try context.fetch(request).first {
                if entity.id == uuid {
                    return entity
                }
            }
            return nil
        } catch {
            print("질문답변 데이터 가져오기 실패: \(error.localizedDescription)")
            return nil
        }
    }

    /// 특정 uuid를 가진 질문답변을 삭제
    /// - Parameters:
    ///   - id: 삭제하고자 하는 질문답변의 고유 아이디
    ///   - context: 코어데이터 컨텍스트
    /// - Returns: 성공 여부 Bool 타입
    func deleteQuestionAnswer(by id: UUID, context: NSManagedObjectContext) -> Bool {
        let fetchRequest: NSFetchRequest<BookQuestionAnswerLinkEntity> =
            BookQuestionAnswerLinkEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "questionAnswer.id == %@", id as CVarArg)

        do {
            let results = try context.fetch(fetchRequest)
            for entity in results {
                context.delete(entity)
            }

            try context.save()
            return true
        } catch {
            print("삭제 실패: \(error.localizedDescription)")
            return false
        }
    }
}
