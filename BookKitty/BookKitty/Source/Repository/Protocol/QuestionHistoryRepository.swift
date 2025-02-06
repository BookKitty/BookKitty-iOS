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

    func saveQuestionAnswer(data: [QuestionAnswer]) -> UUID? // 질문답변 데이터 셋 저장.
}

struct LocalQuestionHistoryRepository: QuestionHistoryRepository {
    // MARK: Lifecycle

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

    // MARK: Internal

    func fetchQuestion(by _: UUID) -> QuestionAnswer? {
        nil
    }

    func saveQuestionAnswer(data _: [QuestionAnswer]) -> UUID? {
        nil
    }

    func fetchQuestions(offset _: Int, limit _: Int) -> RxSwift.Single<[QuestionAnswer]> {
        .just([])
    }

    // MARK: Private

    private let context = CoreDataStack.shared.context
    private let bookCoreDataManager: BookCoreDataManageable
    private let questionAnswerCoreDataManager: QuestionAnswerCoreDataManageable
    private let bookQALinkCoreDataManager: BookQALinkCoreDataManageable
}
