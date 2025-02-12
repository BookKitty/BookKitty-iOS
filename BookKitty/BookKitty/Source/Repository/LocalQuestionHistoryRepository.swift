//
//  LocalQuestionHistoryRepository.swift
//  BookKitty
//
//  Created by 권승용 on 2/11/25.
//

import Foundation
import RxSwift

struct LocalQuestionHistoryRepository: QuestionHistoryRepository {
    // MARK: - Properties

    // MARK: - Private

    private let context = CoreDataStack.shared.context
    private let bookCoreDataManager: BookCoreDataManageable
    private let questionAnswerCoreDataManager: QuestionAnswerCoreDataManageable
    private let bookQALinkCoreDataManager: BookQALinkCoreDataManageable

    // MARK: - Lifecycle

    init(
        bookCoreDataManager: BookCoreDataManageable = BookCoreDataManager(),
        questionAnswerCoreDataManager: QuestionAnswerCoreDataManageable =
            QuestionAnswerCoreDataManager(),
        bookQALinkCoreDataManager: BookQALinkCoreDataManageable = BookQALinkCoreDataManager()
    ) {
        self.bookCoreDataManager = bookCoreDataManager
        self.questionAnswerCoreDataManager = questionAnswerCoreDataManager
        self.bookQALinkCoreDataManager = bookQALinkCoreDataManager
    }

    // MARK: - Functions

    // MARK: - Internal

    /// 질문답변 목록 가져오기
    /// - Parameters:
    ///   - offset: 시작지점
    ///   - limit: 한번에 가져오는 개수
    /// - Returns: 질문답변 데이터 모델을 rx로 반환.
    func fetchQuestions(offset: Int, limit: Int) -> RxSwift.Single<[QuestionAnswer]> {
        let qnaEntities = questionAnswerCoreDataManager.selectQuestionHistories(
            offset: offset,
            limit: limit,
            context: context
        )

        guard !qnaEntities.isEmpty else {
            return .just([])
        }

        let questions: [QuestionAnswer] = qnaEntities.compactMap {
            questionEntityToModel(entity: $0)
        }

        return .just(questions)
    }

    /// 특정 id의 질문답변 데이터 가져오기
    /// - Parameter uuid: 가져오고자 하는 질문답변의 uuid
    /// - Returns: 타겟 질문답변
    func fetchQuestion(by uuid: UUID) -> QuestionAnswer? {
        if let entity = questionAnswerCoreDataManager.selectById(by: uuid, context: context) {
            return questionEntityToModel(entity: entity)
        }
        return nil
    }

    /// 질문답변 저장하기
    /// - Parameter data: 저장하고자 하는 질문답변의 QuestionAnswer 모델 데이터
    /// - Returns: 저장한 데이터의 uuid
    func saveQuestionAnswer(data: QuestionAnswer) -> UUID? {
        let questionEntity = QuestionAnswerEntity(context: context)

        questionEntity.id = data.id
        questionEntity.aiAnswer = data.gptAnswer
        questionEntity.userQuestion = data.userQuestion

        let bookEntities = bookCoreDataManager.createMultipleBooksWithoutSave(
            data: data.recommendedBooks,
            context: context
        )

        let linkEntities = bookEntities.map {
            bookQALinkCoreDataManager.createNewLinkWithoutSave(
                bookEntity: $0,
                questionAnswerEntity: questionEntity,
                context: context
            )
        }

        do {
            try context.save()
            return questionEntity.id
        } catch {
            print("저장 실패: \(error.localizedDescription)")
            return nil
        }
    }

    /// 특정 질문을 삭제
    /// 질문 삭제 시 연결된 책 관련 연결없는 책 삭제 로직 추가 필요.
    ///
    /// - Parameter uuid: 삭제하고자 하는 질문의 uuid
    /// - Returns: 처리 결과 여부를 bool 타입으로 반환.
    func deleteQuestionAnswer(uuid: UUID) -> Bool {
        questionAnswerCoreDataManager.deleteQuestionAnswer(by: uuid, context: context)
    }

    /// 질문 엔티티를 QuestionAnswer 모델로 변경
    /// - Parameter entity: 질문 엔티티
    /// - Returns: QuestionAnswer 모델
    private func questionEntityToModel(entity: QuestionAnswerEntity) -> QuestionAnswer? {
        guard let questionId = entity.id else {
            return nil
        }

        let bookEntities = bookQALinkCoreDataManager.selectLinkedBooksByQuestionId(
            questionId: questionId,
            context: context
        )

        let books = bookEntities.compactMap {
            bookCoreDataManager.entityToModel(entity: $0)
        }

        // TODO: Date, UUID가 새로 생기면 데이터가 달라집니다. id, createdAt이 존재하지 않을 경우 예외처리를 통해 개발자에게 알리는 작업을 추가하면 좋을 듯 합니다!
        return QuestionAnswer(
            createdAt: entity.createdAt ?? Date(),
            userQuestion: entity.userQuestion ?? "",
            gptAnswer: entity.aiAnswer ?? "",
            id: entity.id ?? UUID(),
            recommendedBooks: books
        )
    }
}
