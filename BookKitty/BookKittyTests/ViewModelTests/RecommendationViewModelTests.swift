//
//  RecommendationViewModelTests.swift
//  BookKitty
//
//  Created by 권승용 on 1/31/25.
//

@testable import BookKitty
import BookMatchCore
import Foundation
import RxSwift
import Testing

struct RecommendationViewModelTests {
    // MARK: Internal

    // 테스트: viewDidLoad에서 유저 질문이 올바르게 처리되는지 확인하는 테스트
    @Test
    func test_viewDidLoad_userQuestion() async {
        // RecommendationViewModel 인스턴스 생성
        let vm = QuestionResultViewModel(
            userQuestion: "유저 질문",
            recommendationService: recommendationService,
            bookRepository: bookRepository,
            questionHistoryRepository: questionHistoryRepository
        )

        // 입력 값 정의: 유저 질문 및 기타 이벤트
        let input = QuestionResultViewModel.Input(
            viewDidLoad: .just(()), // 유저 질문
            bookSelected: .empty(), // 선택된 책 없음
            lalalaButtonTapped: .empty() // 버튼 클릭 없음
        )

        // 변환된 출력 값 가져오기
        let output = vm.transform(input)

        // 출력 값이 유저 질문과 일치하는지 확인
        for await value in await output.userQuestion.values {
            #expect(value == "유저 질문")
            break
        }
    }

    // 테스트: viewDidLoad에서 추천 책이 올바르게 처리되는지 확인하는 테스트
    @Test
    func test_viewDidLoad_recommendBook() async {
        // RecommendationViewModel 인스턴스 생성
        let vm = QuestionResultViewModel(
            userQuestion: "유저 질문",
            recommendationService: recommendationService,
            bookRepository: bookRepository,
            questionHistoryRepository: questionHistoryRepository
        )

        // 입력 값 정의: 유저 질문 및 기타 이벤트
        let input = QuestionResultViewModel.Input(
            viewDidLoad: .just(()), // 유저 질문
            bookSelected: .empty(), // 선택된 책 없음
            lalalaButtonTapped: .empty() // 버튼 클릭 없음
        )

        // 변환된 출력 값 가져오기
        let output = vm.transform(input)

        // 출력 값이 추천 책과 일치하는지 확인
        for await value in await output.recommendedBooks.values {
            #expect(
                value[0].items == recommendationService.mockTestCompareData
            )
            break
        }
    }

    // 테스트: 책 선택 이벤트가 올바르게 처리되는지 확인하는 테스트
    @Test
    func test_bookSelected_navigateToBookDetail() async {
        // RecommendationViewModel 인스턴스 생성
        let vm = QuestionResultViewModel(
            userQuestion: "유저 질문",
            recommendationService: recommendationService,
            bookRepository: bookRepository,
            questionHistoryRepository: questionHistoryRepository
        )
        let bookSelectedSubject = PublishSubject<Book>()

        // 입력 값 정의: 책 선택 이벤트
        let input = QuestionResultViewModel.Input(
            viewDidLoad: .empty(), // viewDidLoad 이벤트 없음
            bookSelected: bookSelectedSubject.asObservable(), // 책 선택 이벤트
            lalalaButtonTapped: .empty() // 버튼 클릭 없음
        )

        // 변환된 출력 값 가져오기
        _ = vm.transform(input)

        // PublishSubject에 값을 전달하기 위해 3초후 책 선택 이벤트 발생
        Task {
            try await Task.sleep(nanoseconds: 3_000_000_000)
            bookSelectedSubject.onNext(Constant.testBook)
        }

        // 출력 값이 책 상세 페이지로 이동하는지 확인
        do {
            for try await value in vm.navigateToBookDetail.values {
                #expect(value == Constant.testBook)
                break
            }
        } catch {}
    }

    // 테스트: 버튼 클릭 이벤트가 올바르게 처리되는지 확인하는 테스트
    @Test
    func test_lalalaButtonTapped_navigateToQuestionList() async {
        // RecommendationViewModel 인스턴스 생성
        let vm = QuestionResultViewModel(
            userQuestion: "유저 질문",
            recommendationService: recommendationService,
            bookRepository: bookRepository,
            questionHistoryRepository: questionHistoryRepository
        )
        let lalalaButtonTappedSubject = PublishSubject<Void>()

        // 입력 값 정의: 버튼 클릭 이벤트
        let input = QuestionResultViewModel.Input(
            viewDidLoad: .empty(), // viewDidLoad 이벤트 없음
            bookSelected: .empty(), // 책 선택 이벤트 없음
            lalalaButtonTapped: lalalaButtonTappedSubject.asObservable() // 버튼 클릭 이벤트
        )

        // 변환된 출력 값 가져오기
        _ = vm.transform(input)

        // PublishSubject에 값을 전달하기 위해 3초후 버튼 클릭 이벤트 발생
        Task {
            try await Task.sleep(nanoseconds: 3_000_000_000)
            lalalaButtonTappedSubject.onNext(())
        }

        // 출력 값이 질문 목록 페이지로 이동하는지 확인
        do {
            for try await value in vm.navigateToQuestionHistory.values {
                #expect(value == ())
                break
            }
        } catch {}
    }

    // MARK: Private

    // Mock 서비스 및 리포지토리 인스턴스
    private let recommendationService = MockRecommendationService()
    private let bookRepository = MockBookRepository()
    private let questionHistoryRepository = MockQuestionHistoryRepository()
}

/// 테스트용 상수 정의
private enum Constant {
    /// 테스트용 책 인스턴스
    static let testBook = Book(
        isbn: "978-0-123456-47-2",
        title: "The Swift Journey",
        author: "Alice Johnson",
        publisher: "CodePress",
        thumbnailUrl: URL(string: "https://example.com/swift_journey.jpg")
    )

    /// 테스트용 책 목록
    static let testBookList = [
        Book(
            isbn: "978-0-123456-47-2",
            title: "The Swift Journey",
            author: "Alice Johnson",
            publisher: "CodePress",
            thumbnailUrl: URL(string: "https://example.com/swift_journey.jpg")
        ),
        Book(
            isbn: "1234567890123",
            title: "Swift Programming",
            author: "John Doe",
            publisher: "TechBooks",
            thumbnailUrl: URL(string: "https://bookstore.com/images/1234567890123.jpg")
        ),
    ]
}
