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

    func fetchQuestion(by uuid: UUID) -> QuestionAnswer? {
        if let entity = questionAnswerCoreDataManager.selectById(by: uuid, context: context) {
            return questionEntityToModel(entity: entity)
        }
        return nil
    }

    func saveQuestionAnswer(data: QuestionAnswer) -> UUID? {
        let questionEntity = QuestionAnswerEntity(context: context)

        questionEntity.id = data.id
        questionEntity.aiAnswer = data.gptAnswer
        questionEntity.userQuestion = data.userQuestion
        questionEntity.createdAt = data.createdAt

        let bookEntities = bookCoreDataManager.createMultipleBooksWithoutSave(
            data: data.recommendedBooks,
            context: context
        )

        for item in bookEntities {
            bookQALinkCoreDataManager.createNewLinkWithoutSave(
                bookEntity: item,
                questionAnswerEntity: questionEntity,
                context: context
            )
        }

        do {
            try context.save()
            BookKittyLogger.log("질문답변 저장 성공")
            return questionEntity.id
        } catch {
            BookKittyLogger.log("질문답변 저장 실패: \(error.localizedDescription)")
            return nil
        }
    }

    func deleteQuestionAnswer(uuid: UUID) -> Bool {
        questionAnswerCoreDataManager.deleteQuestionAnswer(by: uuid, context: context)
    }

    private func questionEntityToModel(entity: QuestionAnswerEntity) -> QuestionAnswer {
        let bookEntities = (entity.bookQuestionAnswerLinks as? Set<BookQuestionAnswerLinkEntity>)?
            .compactMap(\.book) ?? []

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
