//
//  QuestionAnswer.swift
//  BookKitty
//
//  Created by 권승용 on 1/30/25.
//

import Foundation

/// 질문답변을 나타내는 모델
struct QuestionAnswer {
    let createdAt: Date
    let userQuestion: String
    let gptAnswer: String
    let recommendedBooks: [Book]
}
