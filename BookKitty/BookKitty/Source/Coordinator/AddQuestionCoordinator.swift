//
//  AddQuestionCoordinator.swift
//  BookKitty
//
//  Created by 전성규 on 2/3/25.
//

import RxCocoa
import RxSwift
import UIKit

/// 사용자가 새 질문을 추가하는 플로우를 관리하는 Coordinator
final class AddQuestionCoordinator: Coordinator {
    // MARK: Lifecycle

    init(_ navigationController: UINavigationController) {
        self.navigationController = navigationController
        newQuestionViewModel = NewQuestionViewModel()
        newQuestionViewController = NewQuestionViewController(viewModel: newQuestionViewModel)
    }

    // MARK: Internal

    var parentCoordinator: Coordinator?
    var childCoordinators: [Coordinator] = []

    var navigationController: UINavigationController
    var newQuestionViewController: NewQuestionViewController

    var newQuestionViewModel: NewQuestionViewModel

    func start() { showNewQuestionScene() }

    // MARK: Private

    private let disposeBag = DisposeBag()
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
        let questionResultViewModel = QuestionResultViewModel()
        let questionResultViewController =
            QuestionResultViewController(viewModel: questionResultViewModel)

        // 질문 결과 ViewModel에 사용자가 입력한 질문 전달
        questionResultViewModel.questionRelay.accept(question)

        // 책 상세 화면으로 이동하는 이벤트를 구독
        questionResultViewModel.navigateToBookDetail
            .withUnretained(self)
            .bind(onNext: { owner, isbn in
                owner.showBookDetailScene(with: isbn)
            }).disposed(by: disposeBag)

        // 루트 화면으로 이동하는 이벤트를 구독
        questionResultViewModel.navigateToRoot
            .withUnretained(self)
            .bind(onNext: { owner, _ in
                owner.navigationController.popViewController(animated: true)
                owner.parentCoordinator?.childCoordinators.removeLast() // AddQuestionCoordinator 제거
            }).disposed(by: disposeBag)

        navigationController.pushViewController(questionResultViewController, animated: true)
        // 네비게이션 스택에서 `NewQuestionViewController` 제거
        navigationController.viewControllers = navigationController.viewControllers.filter {
            !($0 is NewQuestionViewController)
        }
    }

    /// 책 상세 화면을 표시하는 메서드
    /// - Parameter isbn: 선택한 책의 ISBN 번호
    private func showBookDetailScene(with isbn: String) {
        let bookDetailViewModel = BookDetailViewModel()
        bookDetailViewModel.isbnRelay.accept(isbn)

        let bookDetailViewController = BookDetailViewController(viewModel: bookDetailViewModel)

        navigationController.pushViewController(bookDetailViewController, animated: true)
    }
}
