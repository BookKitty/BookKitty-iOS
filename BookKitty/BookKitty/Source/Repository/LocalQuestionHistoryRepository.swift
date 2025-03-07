//
//  LocalQuestionHistoryRepository.swift
//  BookKitty
//
//  Created by 권승용 on 2/11/25.
//

import FirebaseAnalytics
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
    func fetchQuestions(offset: Int, limit: Int) -> [QuestionAnswer] {
        let qnaEntities = questionAnswerCoreDataManager.selectQuestionHistories(
            offset: offset,
            limit: limit,
            context: context
        )

        guard !qnaEntities.isEmpty else {
            return []
        }

        return qnaEntities.compactMap {
            questionEntityToModel(entity: $0)
        }
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
        questionEntity.createdAt = Date()

        let beforeCount = data.recommendedBooks.count
        var afterCount = beforeCount
        let bookEntities = data.recommendedBooks.map {
            if let book = bookCoreDataManager.selectBookByIsbn(isbn: $0.isbn, context: context) {
                afterCount -= 1
                return book
            }
            BookKittyLogger.log("\(beforeCount)만큼 책 가져왔지만, \(afterCount)만큼 저장.")
            return bookCoreDataManager.modelToEntity(model: $0, context: context)
        }

        _ = bookEntities.map {
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
            BookKittyLogger.log("저장 실패: \(error.localizedDescription)")
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

        var books = bookEntities.compactMap {
            bookCoreDataManager.entityToModel(entity: $0)
        }

        books.sort {
            if $0.isOwned == $1.isOwned {
                return $0.title < $1.title
            }
            return $0.isOwned && !$1.isOwned
        }

        guard let createdAt = entity.createdAt, let questionId = entity.id else {
            return nil
        }

        return QuestionAnswer(
            createdAt: createdAt,
            userQuestion: entity.userQuestion ?? "",
            gptAnswer: entity.aiAnswer ?? "",
            id: questionId,
            recommendedBooks: books
        )
    }
}

extension LocalQuestionHistoryRepository {
    func recodeAllQuestionCount() {
        let count = questionAnswerCoreDataManager.readAllQuestionCount(context: context)

        Analytics.logEvent("user_question_count", parameters: [
            "count": count,
        ])
    }
}
