//
// AddQuestionCoordinator.swift
// BookKitty
//
// Created by 전성규 on 2/3/25.
//
import BookRecommendationKit
import RxCocoa
import RxSwift
import UIKit

/// 사용자가 새 질문을 추가하는 플로우를 관리하는 Coordinator
final class AddQuestionCoordinator: Coordinator {
    // MARK: - Properties

    // MARK: - Internal

    weak var finishDelegate: CoordinatorFinishDelegate?
    var parentCoordinator: Coordinator?
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    var newQuestionViewController: NewQuestionViewController
    var newQuestionViewModel: NewQuestionViewModel

    // MARK: - Private

    private let disposeBag = DisposeBag()

    // MARK: - Lifecycle

    init(_ navigationController: UINavigationController) {
        self.navigationController = navigationController
        newQuestionViewModel = NewQuestionViewModel()
        newQuestionViewController = NewQuestionViewController(viewModel: newQuestionViewModel)
    }

    // MARK: - Functions

    func start() { showNewQuestionScene() }
}

extension AddQuestionCoordinator {
    /// 새 질문 작성 화면을 표시하는 메서드
    private func showNewQuestionScene() {
        // 질문 결과 화면으로 이동하는 이벤트를 구독
        newQuestionViewModel.navigateToQuestionResult
            .withUnretained(self)
            .bind(onNext: { owner, question in
                owner.showQuestionResultScene(with: question)
            }).disposed(by: disposeBag)
        // 루트 화면으로 이동하는 이벤트를 구독
        newQuestionViewModel.navigateToRoot
            .withUnretained(self)
            .bind(onNext: { owner, _ in
                owner.navigationController.popViewController(animated: true)
                owner.parentCoordinator?.childCoordinators.removeLast() // AddQuestionCoordinator 제거
            }).disposed(by: disposeBag)
        navigationController.pushViewController(newQuestionViewController, animated: true)
    }

    /// 질문 결과 화면을 표시하는 메서드
    /// - Parameter question: 사용자가 입력한 질문 내용
    private func showQuestionResultScene(with question: String) {
        let recommendationService = BookRecommendationKit(
            naverClientId: Environment().naverClientID,
            naverClientSecret: Environment().naverClientSecret,
            openAIApiKey: Environment().openaiAPIKey
        )
        let repository = LocalBookRepository()
        let questionHistoryRepository = LocalQuestionHistoryRepository()
        let questionResultViewModel = QuestionResultViewModel(
            userQuestion: question,
            recommendationService: recommendationService,
            bookRepository: repository,
            questionHistoryRepository: questionHistoryRepository
        )
        let questionResultViewController =
            QuestionResultViewController(viewModel: questionResultViewModel)
        // 책 상세 화면으로 이동하는 이벤트를 구독
        questionResultViewModel.navigateToBookDetail
            .withUnretained(self)
            .bind(onNext: { owner, book in
                owner.showBookDetailScene(with: book)
            }).disposed(by: disposeBag)
        questionResultViewModel.navigateToQuestionHistory
            .withUnretained(self)
            .bind(onNext: { owner, _ in
                owner.finish()
            }).disposed(by: disposeBag)
        navigationController.pushViewController(questionResultViewController, animated: true)
        // 네비게이션 스택에서 `NewQuestionViewController` 제거
        navigationController.viewControllers = navigationController.viewControllers.filter {
            !($0 is NewQuestionViewController)
        }
    }

    /// 책 상세 화면을 표시하는 메서드
    /// - Parameter isbn: 선택한 책의 ISBN 번호
    private func showBookDetailScene(with book: Book) {
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
