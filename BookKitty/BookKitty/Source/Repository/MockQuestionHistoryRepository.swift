//
//  MockQuestionHistoryRepository.swift
//  BookKitty
//
//  Created by 권승용 on 1/30/25.
//

import Foundation
import RxSwift

final class MockQuestionHistoryRepository: QuestionHistoryRepository {
    let mockQuestionList = [
        QuestionAnswer(
            createdAt: Date(),
            userQuestion: "책 추천을 받고 싶어요!",
            gptAnswer: "당신의 관심사를 기반으로 몇 가지 책을 추천해드릴게요.",
            recommendedBooks: [
                Book(
                    isbn: "9788983925914",
                    title: "미드나잇 라이브러리",
                    author: "매트 헤이그",
                    publisher: "인플루엔셜",
                    thumbnailUrl: URL(string: "https://picsum.photos/200/300")
                ),
            ]
        ),
        QuestionAnswer(
            createdAt: Date(),
            userQuestion: "자기계발 관련 책 추천해주세요.",
            gptAnswer: "자기계발에 좋은 책 몇 권을 추천해드릴게요.",
            recommendedBooks: [
                Book(
                    isbn: "9788901219943",
                    title: "아침의 기적",
                    author: "할 엘로드",
                    publisher: "한빛비즈",
                    thumbnailUrl: URL(string: "https://picsum.photos/200/300")
                ),
                Book(
                    isbn: "9788970123456",
                    title: "성공하는 사람들의 7가지 습관",
                    author: "스티븐 코비",
                    publisher: "김영사",
                    thumbnailUrl: URL(string: "https://picsum.photos/200/300")
                ),
            ]
        ),
        QuestionAnswer(
            createdAt: Date(),
            userQuestion: "책 추천을 받고 싶어요!",
            gptAnswer: "당신의 관심사를 기반으로 몇 가지 책을 추천해드릴게요.",
            recommendedBooks: [
                Book(
                    isbn: "9788983925914",
                    title: "미드나잇 라이브러리",
                    author: "매트 헤이그",
                    publisher: "인플루엔셜",
                    thumbnailUrl: URL(string: "https://picsum.photos/200/300")
                ),
            ]
        ),
        QuestionAnswer(
            createdAt: Date(),
            userQuestion: "자기계발 관련 책 추천해주세요.",
            gptAnswer: "자기계발에 좋은 책 몇 권을 추천해드릴게요.",
            recommendedBooks: [
                Book(
                    isbn: "9788901219943",
                    title: "아침의 기적",
                    author: "할 엘로드",
                    publisher: "한빛비즈",
                    thumbnailUrl: URL(string: "https://picsum.photos/200/300")
                ),
                Book(
                    isbn: "9788970123456",
                    title: "성공하는 사람들의 7가지 습관",
                    author: "스티븐 코비",
                    publisher: "김영사",
                    thumbnailUrl: URL(string: "https://picsum.photos/200/300")
                ),
            ]
        ),
    ]

    func removeQuestion(_: QuestionAnswer) {
        print("question removed")
    }

    func saveQuestion(_: QuestionAnswer) {
        print("questionSaved")
    }

    func fetchQuestions(offset _: Int, limit _: Int) -> Single<[QuestionAnswer]> {
        Single.create { observer in
            observer(.success(self.mockQuestionList))
            return Disposables.create()
        }
    }
}
