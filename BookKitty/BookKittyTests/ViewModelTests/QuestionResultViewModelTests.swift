//
//  QuestionResultViewModelTests.swift
//  BookKitty
//
//  Created by 권승용 on 1/31/25.
//

@testable import BookKitty
import BookMatchCore
import Foundation
import RxSwift
import Testing

/// 테스트 스위트 정의: 테스트가 직렬화되어 실행되도록 설정
@Suite(.serialized)
@MainActor
struct QuestionResultViewModelTests {
    // MARK: - Properties

    // MARK: - Private

    private let recommendationService = MockRecommendationService()
    private let bookRepository = MockBookRepository()
    private let questionHistoryRepository = MockQuestionHistoryRepository()
    private let testQuestion = "좋은 소설 추천해주세요"

    // MARK: - Functions

    // MARK: - Tests

    /// 뷰가 로드될 때 사용자의 질문이 올바르게 표시되는지 테스트
    @Test("viewDidLoad -> 사용자 질문 표시")
    func test_viewDidLoad() async throws {
        let vm = QuestionResultViewModel(
            userQuestion: testQuestion,
            recommendationService: recommendationService,
            bookRepository: bookRepository,
            questionHistoryRepository: questionHistoryRepository
        )

        let input = QuestionResultViewModel.Input(
            viewDidLoad: Observable.just(()),
            viewWillAppear: Observable.empty(),
            bookSelected: Observable.empty(),
            submitButtonTapped: Observable.empty(),
            alertConfirmButtonTapped: Observable.empty()
        )

        let output = vm.transform(input)

        for try await value in output.userQuestion.asObservable().values {
            #expect(value == testQuestion)
            break
        }
    }

    /// 책이 선택됐을 때 상세화면으로 이동하는지 테스트
    @Test("bookSelected -> 책 상세 화면 이동")
    func test_bookSelected() async throws {
        let vm = QuestionResultViewModel(
            userQuestion: testQuestion,
            recommendationService: recommendationService,
            bookRepository: bookRepository,
            questionHistoryRepository: questionHistoryRepository
        )

        let selectedBookSubject = PublishSubject<Book>()

        let input = QuestionResultViewModel.Input(
            viewDidLoad: Observable.empty(),
            viewWillAppear: Observable.empty(),
            bookSelected: selectedBookSubject.asObservable(),
            submitButtonTapped: Observable.empty(),
            alertConfirmButtonTapped: Observable.empty()
        )

        _ = vm.transform(input)

        Task {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            selectedBookSubject.onNext(bookRepository.mockBookList[0])
        }

        do {
            for try await value in vm.navigateToBookDetail.values {
                #expect(value == bookRepository.mockBookList[0])
                break
            }
        } catch {}
    }

    /// 제출 버튼이 탭됐을 때 히스토리 화면으로 이동하는지 테스트
    @Test("submitButtonTapped -> 히스토리 화면 이동")
    func test_submitButtonTapped() async throws {
        let vm = QuestionResultViewModel(
            userQuestion: testQuestion,
            recommendationService: recommendationService,
            bookRepository: bookRepository,
            questionHistoryRepository: questionHistoryRepository
        )

        let submitButtonTappedSubject = PublishSubject<Void>()

        let input = QuestionResultViewModel.Input(
            viewDidLoad: Observable.empty(),
            viewWillAppear: Observable.empty(),
            bookSelected: Observable.empty(),
            submitButtonTapped: submitButtonTappedSubject.asObservable(),
            alertConfirmButtonTapped: Observable.empty()
        )

        _ = vm.transform(input)

        Task {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            submitButtonTappedSubject.onNext(())
        }

        for try await value in vm.navigateToQuestionHistory.values {
            #expect(value == ())
            break
        }
    }
}
