//
//  QuestionAnswerCoreDataManager.swift
//  BookKitty
//
//  Created by 임성수 on 1/23/25.
//

import CoreData
import FirebaseAnalytics

/// QuestionAnswer 엔티티를 관리하는 객체
final class QuestionAnswerCoreDataManager: QuestionAnswerCoreDataManageable {
    /// 이전 질문 목록 가져오기
    /// - Parameters:
    ///   - offset: 아이템을 가져오기 시작하는 지점
    ///   - limit: 한번에 가져오는 아이템의 최대 개수. 0이면 모두 가져옵니다.
    ///   - context: 코어데이터 컨텍스트
    /// - Returns: 조건을 충족하는 BookEntity 배열
    func selectQuestionHistories(
        offset: Int,
        limit: Int,
        context: NSManagedObjectContext
    ) -> [QuestionAnswerEntity] {
        let request: NSFetchRequest<QuestionAnswerEntity> = QuestionAnswerEntity.fetchRequest()
        request.fetchOffset = offset

        if limit > 0 {
            request.fetchLimit = limit
        }

        // createdAt 내림차순 정렬 추가
        let sortDescriptor = NSSortDescriptor(key: "createdAt", ascending: false)
        request.sortDescriptors = [sortDescriptor]

        do {
            let fetchResult = try context.fetch(request)
            BookKittyLogger.log("질문답변 목록 가져오기 성공")
            return fetchResult
        } catch {
            BookKittyLogger.log("질문답변 목록 가져오기 실패: \(error.localizedDescription)")
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
                    BookKittyLogger.log("질문답변 데이터 가져오기 성공")
                    return entity
                }
            }
            return nil
        } catch {
            BookKittyLogger.log("질문답변 데이터 가져오기 실패: \(error.localizedDescription)")
            return nil
        }
    }

    /// 특정 uuid를 가진 질문답변을 삭제
    /// - Parameters:
    ///   - id: 삭제하고자 하는 질문답변의 고유 아이디
    ///   - context: 코어데이터 컨텍스트
    /// - Returns: 성공 여부 Bool 타입
    func deleteQuestionAnswer(by id: UUID, context: NSManagedObjectContext) -> Bool {
        let questionFetchRequest: NSFetchRequest<QuestionAnswerEntity> = QuestionAnswerEntity
            .fetchRequest()
        questionFetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)

        do {
            guard let questionEntity = try context.fetch(questionFetchRequest).first else {
                BookKittyLogger.log("삭제할 질문답변을 찾을 수 없음")
                return false
            }

            let linkFetchRequest: NSFetchRequest<BookQuestionAnswerLinkEntity> =
                BookQuestionAnswerLinkEntity.fetchRequest()
            linkFetchRequest.predicate = NSPredicate(format: "questionAnswer == %@", questionEntity)

            let linkResults = try context.fetch(linkFetchRequest)
            for entity in linkResults {
                context.delete(entity)
            }

            context.delete(questionEntity) // 질문-답변도 함께 삭제

            try context.save()
            BookKittyLogger.log("질문답변 삭제 성공")
            return true
        } catch {
            BookKittyLogger.log("질문답변 삭제 실패: \(error.localizedDescription)")
            return false
        }
    }

    func readAllQuestionCount(context: NSManagedObjectContext) -> Int {
        let request: NSFetchRequest<QuestionAnswerEntity> = QuestionAnswerEntity.fetchRequest()

        do {
            return try context.count(for: request)
        } catch {
            BookKittyLogger.log("질문 개수 가져오기 실패: \(error.localizedDescription)")
            return 0
        }
    }
}
