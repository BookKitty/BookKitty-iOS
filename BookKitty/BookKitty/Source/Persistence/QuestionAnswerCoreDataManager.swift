//
//  QuestionAnswerCoreDataManager.swift
//  BookKitty
//
//  Created by 임성수 on 1/23/25.
//

import CoreData

/// QuestionAnswer 엔티티를 관리하는 코어 데이터 매니저 기능을 추상화하는 프로토콜
protocol QuestionAnswerCoreDataManageable {
    /// 내부 요구사항은 추후 변경됩니다
    func selectQuestionHistories(offset: Int, limit: Int, context: NSManagedObjectContext)
        -> [QuestionAnswerEntity]
}

/// QuestionAnswer 엔티티를 관리하는 객체
final class QuestionAnswerCoreDataManager: QuestionAnswerCoreDataManageable {
    func entityToModel(entity _: QuestionAnswerEntity) -> QuestionAnswer? {
        nil
    }

    func create() {}

    func read() {}

    func delete() {}

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
}
