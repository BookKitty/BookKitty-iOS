//
//  QuestionHistoryRepository.swift
//  BookKitty
//
//  Created by 권승용 on 1/30/25.
//

import RxSwift

protocol QuestionHistoryRepository {
    func fetchQuestions() -> Single<[Question]>
}
