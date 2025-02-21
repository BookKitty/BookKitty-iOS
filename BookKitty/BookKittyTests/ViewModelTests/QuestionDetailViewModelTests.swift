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

@Suite(.serialized)
@MainActor
struct QuestionDetailViewModelTests {
    // MARK: - Properties

    private let repository = MockQuestionHistoryRepository()
    private let mockBooks = MockBookRepository().mockBookList

    private let mockQnA = QuestionAnswer(
        createdAt: Date(),
        userQuestion: "테스트 질문",
        gptAnswer: "테스트 답변",
        id: UUID(),
        recommendedBooks: MockBookRepository().mockBookList
    )

    // MARK: - Functions

    /// viewDidLoad 시 데이터가 올바르게 표시되는지 테스트
    @Test("viewDidLoad -> 데이터 표시")
    func test_viewDidLoad() async {
        let vm = QuestionDetailViewModel(
            questionAnswer: mockQnA,
            questionHistoryRepository: repository
        )

        let input = QuestionDetailViewModel.Input(
            viewDidLoad: Observable.just(()),
            viewWillAppear: Observable.empty(),
            deleteButtonTapped: Observable.empty(),
            backButtonTapped: Observable.empty(),
            bookTapped: Observable.empty()
        )

        let output = vm.transform(input)

        for await value in output.userQuestion.values {
            #expect(value == "테스트 질문")
            break
        }

        for await value in output.recommendationReason.values {
            #expect(value == "테스트 답변")
            break
        }

        for await value in output.recommendedBooks.values {
            #expect(value[0].items == mockBooks)
            break
        }
    }

    /// 화면 재진입 시 데이터가 업데이트되는지 테스트
    @Test("viewWillAppear -> 데이터 업데이트")
    func test_viewWillAppear() async {
        let vm = QuestionDetailViewModel(
            questionAnswer: mockQnA,
            questionHistoryRepository: repository
        )
        let viewWillAppearSubject = PublishSubject<Void>()

        let input = QuestionDetailViewModel.Input(
            viewDidLoad: Observable.empty(),
            viewWillAppear: viewWillAppearSubject.asObservable(),
            deleteButtonTapped: Observable.empty(),
            backButtonTapped: Observable.empty(),
            bookTapped: Observable.empty()
        )

        let output = vm.transform(input)

        // 첫 번째 viewWillAppear는 스킵됨
        Task {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            viewWillAppearSubject.onNext(())
            viewWillAppearSubject.onNext(())
        }

        var emissionCount = 0
        for await value in output.recommendedBooks.values {
            emissionCount += 1
            if emissionCount > 1 {
                #expect(value[0].items == mockBooks)
                break
            }
        }
    }

    /// 삭제 버튼 탭 시 화면이 dismiss되는지 테스트
    @Test("deleteButtonTapped -> 화면 dismiss")
    func test_deleteButtonTapped() async throws {
        let vm = QuestionDetailViewModel(
            questionAnswer: mockQnA,
            questionHistoryRepository: repository
        )
        let deleteButtonTappedSubject = PublishSubject<Void>()

        let input = QuestionDetailViewModel.Input(
            viewDidLoad: Observable.empty(),
            viewWillAppear: Observable.empty(),
            deleteButtonTapped: deleteButtonTappedSubject.asObservable(),
            backButtonTapped: Observable.empty(),
            bookTapped: Observable.empty()
        )

        _ = vm.transform(input)

        Task {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            deleteButtonTappedSubject.onNext(())
        }

        for try await _ in vm.dismissViewController.values {
            #expect(true)
            break
        }
    }

    /// 뒤로가기 버튼 탭 시 화면이 dismiss되는지 테스트
    @Test("backButtonTapped -> 화면 dismiss")
    func test_backButtonTapped() async throws {
        let vm = QuestionDetailViewModel(
            questionAnswer: mockQnA,
            questionHistoryRepository: repository
        )
        let deleteButtonTappedSubject = PublishSubject<Void>()

        let input = QuestionDetailViewModel.Input(
            viewDidLoad: Observable.empty(),
            viewWillAppear: Observable.empty(),
            deleteButtonTapped: Observable.empty(),
            backButtonTapped: deleteButtonTappedSubject.asObservable(),
            bookTapped: Observable.empty()
        )

        _ = vm.transform(input)

        Task {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            deleteButtonTappedSubject.onNext(())
        }

        for try await _ in vm.dismissViewController.values {
            #expect(true)
            break
        }
    }

    /// 책 탭 시 상세화면으로 이동하는지 테스트
    @Test("bookTapped -> 상세화면 이동")
    func test_bookTapped() async throws {
        let vm = QuestionDetailViewModel(
            questionAnswer: mockQnA,
            questionHistoryRepository: repository
        )
        let bookTappedSubject = PublishSubject<Book>()

        let input = QuestionDetailViewModel.Input(
            viewDidLoad: Observable.empty(),
            viewWillAppear: Observable.empty(),
            deleteButtonTapped: Observable.empty(),
            backButtonTapped: Observable.empty(),
            bookTapped: bookTappedSubject.asObservable()
        )

        _ = vm.transform(input)

        Task {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            bookTappedSubject.onNext(mockBooks[0])
        }

        for try await value in vm.navigateToBookDetail.values {
            #expect(value == mockBooks[0])
            break
        }
    }
}
