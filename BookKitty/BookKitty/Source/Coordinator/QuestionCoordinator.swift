//
//  QuestionCoordinator.swift
//  BookKitty
//
//  Created by 전성규 on 1/26/25.
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
    // MARK: Lifecycle

    init(_ navigationController: UINavigationController) {
        self.navigationController = navigationController
        let repository = MockQuestionHistoryRepository()
        questionHistoryViewModel = QuestionHistoryViewModel(questionRepository: repository)
        questionHistoryViewController =
            QuestionHistoryViewController(viewModel: questionHistoryViewModel)
    }

    // MARK: Internal

    var parentCoordinator: Coordinator?
    var childCoordinators: [Coordinator] = []

    var navigationController: UINavigationController
    var questionHistoryViewController: QuestionHistoryViewController

    var questionHistoryViewModel: QuestionHistoryViewModel

    func start() { showQuestionHistoryScreen() }

    // MARK: Private

    private let disposeBag = DisposeBag()
}

extension DefaultQuestionCoordinator {
    /// 질문 기록 화면 표시
    ///
    /// 질문 상세 화면으로의 네비게이션 이벤트를 구독
    private func showQuestionHistoryScreen() {
        let questionHistoryViewModel =
            QuestionHistoryViewModel(questionRepository: MockQuestionHistoryRepository())
        let questionHistoryViewController =
            QuestionHistoryViewController(viewModel: questionHistoryViewModel)

        // 질문 상세 화면으로의 이동 이벤트 처리
        questionHistoryViewModel.navigateToQuestionDetail
            .withUnretained(self)
            .subscribe(onNext: { coordinator, _ in
                coordinator.showQuestionDetailScreen()
            }).disposed(by: disposeBag)

        navigationController.pushViewController(questionHistoryViewController, animated: true)
    }

    /// 질문 상세 화면 표시
    ///
    /// 질문 상세 화면을 생성하고, ViewModel과 ViewController를 연결
    /// 책 상세 화면으로의 네비게이션 이벤트를 구독
    private func showQuestionDetailScreen() {
        let questionDetailViewModel = QuestionDetailViewModel()
        let questionDetailViewController =
            QuestionDetailViewController(viewModel: questionDetailViewModel)

        // 책 상세 화면으로의 이동 이벤트 처리
        questionDetailViewModel.navigateToBookDetail
            .withUnretained(self)
            .subscribe(onNext: { coordinator, _ in
                coordinator.showBookDetailScreen()
            }).disposed(by: disposeBag)

        questionDetailViewController.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(questionDetailViewController, animated: true)
    }

    /// 책 상세 화면 표시
    ///
    /// 책 상세 화면을 생성하고, ViewModel과 ViewController를 연결
    private func showBookDetailScreen() {
        let bookDetailViewModel = BookDetailViewModel()
        let bookDetailViewController = BookDetailViewController(viewModel: bookDetailViewModel)

        navigationController.pushViewController(bookDetailViewController, animated: true)
    }
}
