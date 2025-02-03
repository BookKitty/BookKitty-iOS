//
//  AddBookCoordinator.swift
//  BookKitty
//
//  Created by 전성규 on 1/31/25.
//

import RxSwift
import UIKit

protocol AddBookCoordinator: Coordinator {
    var addBookViewController: AddBookViewController { get }
}

final class DefaultAddBookCoordinator: AddBookCoordinator {
    // MARK: Lifecycle

    init(_ navigationController: UINavigationController) {
        self.navigationController = navigationController
        addBookViewModel = AddBookViewModel()
        addBookViewController = AddBookViewController(viewModel: addBookViewModel)
    }

    // MARK: Internal

    var parentCoordinator: Coordinator?
    var childCoordinators: [Coordinator] = []

    var navigationController: UINavigationController
    var addBookViewController: AddBookViewController

    var addBookViewModel: AddBookViewModel

    func start() { showAddBookScene() }

    // MARK: Private

    private let disposeBag = DisposeBag()
}

extension DefaultAddBookCoordinator {
    private func showAddBookScene() {
        addBookViewModel.navigateToReviewAddBook
            .withUnretained(self)
            .bind(onNext: { owner, _ in
                owner.showReviewAddBookScene()
            }).disposed(by: disposeBag)

        navigationController.pushViewController(addBookViewController, animated: true)
    }

    private func showReviewAddBookScene() {
        let reviewAddBookViewModel = ReviewAddBookViewModel()
        let reviewAddBookViewController =
            ReviewAddBookViewController(viewModel: reviewAddBookViewModel)

        reviewAddBookViewModel.navigateToBookList
            .withUnretained(self)
            .bind(onNext: { owner, _ in
                owner.finish()
            }).disposed(by: disposeBag)

        navigationController.pushViewController(reviewAddBookViewController, animated: true)
    }
}

extension DefaultAddBookCoordinator {
    private func finish() {
        if let tabBarController = navigationController
            .viewControllers.first(where: { $0 is TabBarController }) {
            navigationController.popToViewController(tabBarController, animated: true)
            parentCoordinator?.childCoordinators.removeLast()
        }
    }
}
