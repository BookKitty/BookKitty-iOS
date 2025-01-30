//
//  Question.swift
//  BookKitty
//
//  Created by 권승용 on 1/30/25.
//

import Foundation

/// 질문답변을 나타내는 모델
/// 더 좋은 네이밍이 있다면 추천해 주세요... 이게 제 한계입니다
struct Question {
    let createdAt: Date
    let userQuestion: String
    let gptAnswer: String
    let recommandedBooks: [Book]
}
