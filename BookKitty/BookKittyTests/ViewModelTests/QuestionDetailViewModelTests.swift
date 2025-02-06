//
//  QuestionDetailViewModelTests.swift
//  BookKitty
//
//  Created by 권승용 on 2/6/25.
//

@testable import BookKitty
import Foundation
import RxSwift
import Testing

@Suite()
struct QuestionDetailViewModelTests {
    // MARK: Internal

    @Test()
    func test_viewDidLoad_questionDate() async {
        let vm = QuestionDetailViewModel(
            questionAnswer: testQuestionAnswer,
            questionHistoryRepository: questionHistoryRepostiroy
        )

        let input = QuestionDetailViewModel.Input(
            viewDidLoad: .just(()),
            deleteButtonTapped: .empty(),
            bookTapped: .empty()
        )

        let output = vm.transform(input)

        for await value in await output.questionDate.values {
            #expect(value == DateFormatHandler().dateString(from: testQuestionAnswer.createdAt))
            break
        }
    }

    @Test()
    func test_viewDidLoad_userQuestion() async {
        let vm = QuestionDetailViewModel(
            questionAnswer: testQuestionAnswer,
            questionHistoryRepository: questionHistoryRepostiroy
        )

        let input = QuestionDetailViewModel.Input(
            viewDidLoad: .just(()),
            deleteButtonTapped: .empty(),
            bookTapped: .empty()
        )

        let output = vm.transform(input)

        for await value in await output.userQuestion.values {
            #expect(value == testQuestionAnswer.userQuestion)
            break
        }
    }

    @Test()
    func test_viewDidLoad_reason() async {
        let vm = QuestionDetailViewModel(
            questionAnswer: testQuestionAnswer,
            questionHistoryRepository: questionHistoryRepostiroy
        )

        let input = QuestionDetailViewModel.Input(
            viewDidLoad: .just(()),
            deleteButtonTapped: .empty(),
            bookTapped: .empty()
        )

        let output = vm.transform(input)

        for await value in await output.recommendationReason.values {
            #expect(value == testQuestionAnswer.gptAnswer)
            break
        }
    }

    @Test()
    func test_viewDidLoad_books() async {
        let vm = QuestionDetailViewModel(
            questionAnswer: testQuestionAnswer,
            questionHistoryRepository: questionHistoryRepostiroy
        )

        let input = QuestionDetailViewModel.Input(
            viewDidLoad: .just(()),
            deleteButtonTapped: .empty(),
            bookTapped: .empty()
        )

        let output = vm.transform(input)

        for await value in await output.recommendedBooks.values {
            #expect(value[0].items == testQuestionAnswer.recommendedBooks)
            break
        }
    }

    @Test()
    func test_deleteButtonTapped_popVC() async throws {
        let vm = QuestionDetailViewModel(
            questionAnswer: testQuestionAnswer,
            questionHistoryRepository: questionHistoryRepostiroy
        )

        let input = QuestionDetailViewModel.Input(
            viewDidLoad: .empty(),
            deleteButtonTapped: deleteButtonTappedSubject,
            bookTapped: .empty()
        )

        _ = vm.transform(input)

        Task {
            try await Task.sleep(nanoseconds: 3_000_000_000)
            deleteButtonTappedSubject.onNext(())
        }

        for try await value in vm.dismissViewController.values {
            #expect(value == ())
            break
        }
    }

    func test_bookSelected_navigateToBookDetail() async throws {
        let vm = QuestionDetailViewModel(
            questionAnswer: testQuestionAnswer,
            questionHistoryRepository: questionHistoryRepostiroy
        )

        let input = QuestionDetailViewModel.Input(
            viewDidLoad: .empty(),
            deleteButtonTapped: .empty(),
            bookTapped: bookSelectedSubject
        )

        _ = vm.transform(input)

        Task {
            try await Task.sleep(nanoseconds: 3_000_000_000)
            bookSelectedSubject.onNext(testBook)
        }

        for try await value in vm.navigateToBookDetail.values {
            #expect(value == testBook)
            break
        }
    }

    // MARK: Private

    private var deleteButtonTappedSubject = PublishSubject<Void>()
    private var bookSelectedSubject = PublishSubject<Book>()

    private let questionHistoryRepostiroy = MockQuestionHistoryRepository()

    private let testQuestionAnswer = QuestionAnswer(
        createdAt: Date(),
        userQuestion: "유저 질문",
        gptAnswer: "지피티 응답",
        recommendedBooks: [
            Book(
                isbn: "102031923",
                title: "책제목",
                author: "저자",
                publisher: "출판사",
                thumbnailUrl: nil
            ),
        ]
    )

    private let testBook = Book(
        isbn: "102031923",
        title: "책제목",
        author: "저자",
        publisher: "출판사",
        thumbnailUrl: nil
    )
}
