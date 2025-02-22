//
//  MockQuestionHistoryRepository.swift
//  BookKitty
//
//  Created by 권승용 on 1/30/25.
//

import Foundation
import RxSwift

final class MockQuestionHistoryRepository: QuestionHistoryRepository {
    // MARK: - Properties

    let mockQuestionList = [
        QuestionAnswer(
            createdAt: Date(),
            userQuestion: "책 추천을 받고 싶어요!",
            gptAnswer: "당신의 관심사를 기반으로 몇 가지 책을 추천해드릴게요.",
            recommendedBooks: [
                Book(
                    isbn: "9788950963262",
                    title: "침묵의 기술",
                    author: "조제프 앙투안 투생 디누아르",
                    publisher: "아르테(arte)",
                    thumbnailUrl: URL(
                        string: "https://shopping-phinf.pstatic.net/main_3249696/32496966995.20240321071044.jpg"
                    ),
                    isOwned: true,
                    createdAt: Date(),
                    updatedAt: Date()
                ),
                Book(
                    isbn: "9788954625760",
                    title: "불안의 책",
                    author: "페르난두 페소아",
                    publisher: "문학동네",
                    thumbnailUrl: URL(
                        string: "https://shopping-phinf.pstatic.net/main_3245596/32455964233.20230822103854.jpg"
                    ),
                    isOwned: true,
                    createdAt: Date(),
                    updatedAt: Date()
                ),
                Book(
                    isbn: "9788981171353",
                    title: "마음챙김 명상",
                    author: "존 카밧진",
                    publisher: "사람과책",
                    thumbnailUrl: URL(
                        string: "https://shopping-phinf.pstatic.net/main_3245593/32455931661.20220527022757.jpg"
                    ),
                    isOwned: false,
                    createdAt: Date(),
                    updatedAt: Date()
                ),
                Book(
                    isbn: "9791196914806",
                    title: "당신 인생의 이야기",
                    author: "테드 창",
                    publisher: "엘리",
                    thumbnailUrl: URL(
                        string: "https://shopping-phinf.pstatic.net/main_3248052/32480522779.20231230070743.jpg"
                    ),
                    isOwned: false,
                    createdAt: Date(),
                    updatedAt: Date()
                ),
            ]
        ),
        QuestionAnswer(
            createdAt: Date(),
            userQuestion: "자기계발 관련 책 추천해주세요.",
            gptAnswer: "자기계발에 좋은 책 몇 권을 추천해드릴게요.",
            recommendedBooks: [
                Book(
                    isbn: "9788954625760",
                    title: "불안의 책",
                    author: "페르난두 페소아",
                    publisher: "문학동네",
                    thumbnailUrl: URL(
                        string: "https://shopping-phinf.pstatic.net/main_3245596/32455964233.20230822103854.jpg"
                    ),
                    isOwned: true,
                    createdAt: Date(),
                    updatedAt: Date()
                ),
                Book(
                    isbn: "9788950963262",
                    title: "침묵의 기술",
                    author: "조제프 앙투안 투생 디누아르",
                    publisher: "아르테(arte)",
                    thumbnailUrl: URL(
                        string: "https://shopping-phinf.pstatic.net/main_3249696/32496966995.20240321071044.jpg"
                    ),
                    isOwned: false,
                    createdAt: Date(),
                    updatedAt: Date()
                ),
            ]
        ),
        QuestionAnswer(
            createdAt: Date(),
            userQuestion: "책 추천을 받고 싶어요!",
            gptAnswer: "당신의 관심사를 기반으로 몇 가지 책을 추천해드릴게요.",
            recommendedBooks: [
                Book(
                    isbn: "9788925562599",
                    title: "아르테미스",
                    author: "앤디 위어",
                    publisher: "알에이치코리아",
                    thumbnailUrl: URL(
                        string: "https://shopping-phinf.pstatic.net/main_3250617/32506170687.20230425164240.jpg"
                    ),
                    isOwned: true,
                    createdAt: Date(),
                    updatedAt: Date()
                ),
                Book(
                    isbn: "9791196914806",
                    title: "당신 인생의 이야기",
                    author: "테드 창",
                    publisher: "엘리",
                    thumbnailUrl: URL(
                        string: "https://shopping-phinf.pstatic.net/main_3248052/32480522779.20231230070743.jpg"
                    ),
                    isOwned: true,
                    createdAt: Date(),
                    updatedAt: Date()
                ),
                Book(
                    isbn: "9788960776654",
                    title: "레디 플레이어 원",
                    author: "어니스트 클라인",
                    publisher: "에이콘출판",
                    thumbnailUrl: URL(
                        string: "https://shopping-phinf.pstatic.net/main_3244556/32445566826.20230711113711.jpg"
                    ),
                    isOwned: false,
                    createdAt: Date(),
                    updatedAt: Date()
                ),
                Book(
                    isbn: "9788947529877",
                    title: "제로 투 원",
                    author: "피터 틸",
                    publisher: "한국경제신문",
                    thumbnailUrl: URL(
                        string: "https://shopping-phinf.pstatic.net/main_3249205/32492052879.20220520205540.jpg"
                    ),
                    isOwned: false,
                    createdAt: Date(),
                    updatedAt: Date()
                ),
                Book(
                    isbn: "9788996421221",
                    title: "스타트업 바이블",
                    author: "배기홍",
                    publisher: "파이카",
                    thumbnailUrl: URL(
                        string: "https://shopping-phinf.pstatic.net/main_3249273/32492733482.20220527030018.jpg"
                    ),
                    isOwned: false,
                    createdAt: Date(),
                    updatedAt: Date()
                ),
                Book(
                    isbn: "9788966260577",
                    title: "린 스타트업",
                    author: "에릭 리스",
                    publisher: "인사이트",
                    thumbnailUrl: URL(
                        string: "https://shopping-phinf.pstatic.net/main_3243612/32436122059.20230912084228.jpg"
                    ),
                    isOwned: false,
                    createdAt: Date(),
                    updatedAt: Date()
                ),
            ]
        ),
        QuestionAnswer(
            createdAt: Date(),
            userQuestion: "자기계발 관련 책 추천해주세요.",
            gptAnswer: "자기계발에 좋은 책 몇 권을 추천해드릴게요.",
            recommendedBooks: [
                Book(
                    isbn: "9788947529877",
                    title: "제로 투 원",
                    author: "피터 틸",
                    publisher: "한국경제신문",
                    thumbnailUrl: URL(
                        string: "https://shopping-phinf.pstatic.net/main_3249205/32492052879.20220520205540.jpg"
                    ),
                    isOwned: true,
                    createdAt: Date(),
                    updatedAt: Date()
                ),
                Book(
                    isbn: "9788996421221",
                    title: "스타트업 바이블",
                    author: "배기홍",
                    publisher: "파이카",
                    thumbnailUrl: URL(
                        string: "https://shopping-phinf.pstatic.net/main_3249273/32492733482.20220527030018.jpg"
                    ),
                    isOwned: false,
                    createdAt: Date(),
                    updatedAt: Date()
                ),
                Book(
                    isbn: "9788966260577",
                    title: "린 스타트업",
                    author: "에릭 리스",
                    publisher: "인사이트",
                    thumbnailUrl: URL(
                        string: "https://shopping-phinf.pstatic.net/main_3243612/32436122059.20230912084228.jpg"
                    ),
                    isOwned: false,
                    createdAt: Date(),
                    updatedAt: Date()
                ),
            ]
        ),
    ]

    // MARK: - Functions

    func fetchQuestion(by _: UUID) -> QuestionAnswer? {
        mockQuestionList[0]
    }

    func saveQuestionAnswer(data _: QuestionAnswer) -> UUID? {
        UUID()
    }

    func deleteQuestionAnswer(uuid _: UUID) -> Bool {
        true
    }

    func fetchQuestions(offset _: Int, limit _: Int) -> Single<[QuestionAnswer]> {
        Single.create { observer in
            observer(.success(self.mockQuestionList))
            return Disposables.create()
        }
    }

    func fetchQuestions(offset _: Int, limit _: Int) -> [QuestionAnswer] {
        mockQuestionList
    }

    func recodeAllQuestionCount() {
        print(mockQuestionList.count)
    }
}
