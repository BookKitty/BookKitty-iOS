//
// QuestionCoordinator.swift
// BookKitty
//
// Created by 전성규 on 1/26/25.
//
import RxRelay
import RxSwift
import UIKit

protocol QuestionCoordinator: Coordinator {
    var questionHistoryViewController: QuestionHistoryViewController { get }
}

/// 질문 관련 화면 흐름을 관리하는 Coordinator
///
/// `QuestionCoordinator`는 질문 기록, 질문 상세, 책 상세와 같은 화면 전환을 관리.
final class DefaultQuestionCoordinator: QuestionCoordinator {
    // MARK: - Properties

    // MARK: - Internal

    weak var finishDelegate: CoordinatorFinishDelegate?
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    var questionHistoryViewController: QuestionHistoryViewController
    var questionHistoryViewModel: QuestionHistoryViewModel

    // MARK: - Private

    private let disposeBag = DisposeBag()

    // MARK: - Lifecycle

    init(_ navigationController: UINavigationController) {
        self.navigationController = navigationController

        let repository = LocalQuestionHistoryRepository()
        questionHistoryViewModel = QuestionHistoryViewModel(questionHistoryRepository: repository)
        questionHistoryViewController =
            QuestionHistoryViewController(viewModel: questionHistoryViewModel)
    }

    // MARK: - Functions

    func start() { showQuestionHistoryScreen() }
}

extension DefaultQuestionCoordinator {
    /// 질문 기록 화면 표시
    ///
    /// 질문 상세 화면으로의 네비게이션 이벤트를 구독
    private func showQuestionHistoryScreen() {
        // 질문 상세 화면으로의 이동 이벤트 처리
        questionHistoryViewModel.navigateToQuestionDetail
            .withUnretained(self)
            .subscribe(onNext: { coordinator, questionAnswer in
                coordinator.showQuestionDetailScreen(questionAnswer: questionAnswer)
            }).disposed(by: disposeBag)
    }

    /// 질문 상세 화면 표시
    ///
    /// 질문 상세 화면을 생성하고, ViewModel과 ViewController를 연결
    /// 책 상세 화면으로의 네비게이션 이벤트를 구독
    private func showQuestionDetailScreen(questionAnswer: QuestionAnswer) {
        let questionHistoryRepository = LocalQuestionHistoryRepository()
        let questionDetailViewModel = QuestionDetailViewModel(
            questionAnswer: questionAnswer,
            questionHistoryRepository: questionHistoryRepository
        )
        let questionDetailViewController =
            QuestionDetailViewController(viewModel: questionDetailViewModel)
        // 책 상세 화면으로의 이동 이벤트 처리
        questionDetailViewModel.navigateToBookDetail
            .withUnretained(self)
            .subscribe(onNext: { coordinator, book in
                coordinator.showBookDetailScreen(with: book)
            }).disposed(by: disposeBag)

        questionDetailViewModel.dismissViewController
            .withUnretained(self)
            .bind(onNext: { owner, _ in
                owner.navigationController.popViewController(animated: true)
            }).disposed(by: disposeBag)

        questionDetailViewController.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(questionDetailViewController, animated: true)
    }

    /// 책 상세 화면 표시
    ///
    /// 책 상세 화면을 생성하고, ViewModel과 ViewController를 연결
    private func showBookDetailScreen(with book: Book) {
        let bookRepository = LocalBookRepository()
        let bookDetailViewModel = BookDetailViewModel(
            bookDetail: book,
            bookRepository: bookRepository
        )
        let bookDetailViewController = BookDetailViewController(viewModel: bookDetailViewModel)
        bookDetailViewModel.navigateBackRelay
            .observe(on: MainScheduler.instance)
            .withUnretained(self)
            .bind(onNext: { owner, _ in
                owner.navigationController.popViewController(animated: true)
            }).disposed(by: disposeBag)
        navigationController.pushViewController(bookDetailViewController, animated: true)
    }
}
