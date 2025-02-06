//
//  QuestionHistoryRepository.swift
//  BookKitty
//
//  Created by 권승용 on 1/30/25.
//

import RxSwift

protocol QuestionHistoryRepository {
    func fetchQuestions(offset: Int, limit: Int) -> Single<[QuestionAnswer]>
    func saveQuestion(_ question: QuestionAnswer)
    func removeQuestion(_ question: QuestionAnswer)
}
