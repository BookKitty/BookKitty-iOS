//
//  MockQuestionHistoryRepository.swift
//  BookKitty
//
//  Created by 권승용 on 1/30/25.
//

import RxSwift

final class MockQuestionHistoryRepository: QuestionHistoryRepository {
    func fetchQuestions() -> Single<[Question]> {
        .just([])
    }
}
