//
//  QuestionAnswer.swift
//  BookKitty
//
//  Created by 권승용 on 1/30/25.
//

import Foundation

/// 질문답변을 나타내는 모델
struct QuestionAnswer: Hashable {
    // MARK: - Lifecycle

    init(
        createdAt: Date = Date(),
        userQuestion: String = "답을 알려주세요.",
        gptAnswer: String = "이 책을 읽어보세요.",
        id: UUID = UUID(),
        recommendedBooks: [Book]
    ) {
        self.createdAt = createdAt
        self.userQuestion = userQuestion
        self.gptAnswer = gptAnswer
        self.id = id
        self.recommendedBooks = recommendedBooks
    }

    // MARK: - Internal

    let createdAt: Date
    let userQuestion: String
    let gptAnswer: String
    let id: UUID
    let recommendedBooks: [Book]
}
