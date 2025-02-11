//
//  QuestionHistoryRepository.swift
//  BookKitty
//
//  Created by 권승용 on 1/30/25.
//

import Foundation
import RxSwift

protocol QuestionHistoryRepository {
    func fetchQuestions(offset: Int, limit: Int) -> Single<[QuestionAnswer]>
    func fetchQuestion(by id: UUID) -> QuestionAnswer? // uuid 로 특정 퀘스쳔 정보 가져오기

    func saveQuestionAnswer(data: QuestionAnswer) -> UUID? // 질문답변 데이터 셋 저장.
    func deleteQuestionAnswer(uuid: UUID) -> Bool // 삭제 성공 여부를 bool값으로 반환.
}

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

        questionEntity.id = UUID()
        questionEntity.aiAnswer = data.gptAnswer
        questionEntity.userQuestion = data.userQuestion

        let bookEntities = bookCoreDataManager.createMultipleBooksWithoutSave(
            data: data.recommendedBooks,
            context: context
        )

        let _ = bookEntities.map {
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

    func deleteQuestionAnswer(uuid: UUID) -> Bool {
        questionAnswerCoreDataManager.deleteQuestionAnswer(by: uuid, context: context)
    }

    private func questionEntityToModel(entity: QuestionAnswerEntity) -> QuestionAnswer {
        let bookEntities = (entity.bookQuestionAnswerLinks as? Set<BookQuestionAnswerLinkEntity>)?
            .compactMap(\.book) ?? []

        let books = bookEntities.compactMap {
            bookCoreDataManager.entityToModel(entity: $0)
        }

        return QuestionAnswer(
            createdAt: entity.createdAt ?? Date(),
            userQuestion: entity.userQuestion ?? "",
            gptAnswer: entity.aiAnswer ?? "",
            id: entity.id ?? UUID(),
            recommendedBooks: books
        )
    }
}
