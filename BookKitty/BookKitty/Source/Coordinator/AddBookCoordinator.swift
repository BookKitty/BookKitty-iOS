//
//  AddBookCoordinator.swift
//  BookKitty
//
//  Created by 반성준 on 1/31/25.
//

import RxSwift
import UIKit

protocol AddBookCoordinator: Coordinator {
    var addBookViewController: AddBookViewController { get }
}

final class DefaultAddBookCoordinator: AddBookCoordinator {
    // MARK: Lifecycle

    // MARK: - Initialization

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

    // MARK: - Private Properties

    private let disposeBag = DisposeBag()
}

// MARK: - Navigation Logic

extension DefaultAddBookCoordinator {
    private func showAddBookScene() {
        let output = addBookViewModel.transform(
            AddBookViewModel.Input(
                captureButtonTapped: addBookViewController.captureButton.rx.tap.asObservable(),
                manualAddButtonTapped: addBookViewController.addBookButton.rx.tap.asObservable(),
                confirmButtonTapped: addBookViewController.confirmButton.rx.tap.asObservable()
            )
        )

        output.navigateToReviewAddBook
            .subscribe(onNext: { [weak self] bookList in
                self?.showReviewAddBookScene(bookList: bookList)
            })
            .disposed(by: disposeBag)

        navigationController.pushViewController(addBookViewController, animated: true)
    }

    private func showReviewAddBookScene(bookList: [String]) {
        let reviewAddBookViewModel = ReviewAddBookViewModel(initialBookList: bookList)
        let reviewAddBookViewController =
            ReviewAddBookViewController(viewModel: reviewAddBookViewModel)

        // ✅ `navigateToBookListRelay`가 `internal`로 변경되어 접근 가능
        reviewAddBookViewModel.navigateToBookListRelay
            .subscribe(onNext: { [weak self] in
                self?.finish()
            })
            .disposed(by: disposeBag)

        navigationController.pushViewController(reviewAddBookViewController, animated: true)
    }
}

// MARK: - Finish Navigation

extension DefaultAddBookCoordinator {
    private func finish() {
        if let tabBarController = navigationController
            .viewControllers.first(where: { $0 is TabBarController }) {
            navigationController.popToViewController(tabBarController, animated: true)

            if let parent = parentCoordinator {
                parent.childCoordinators.removeAll { $0 === self }
            }
        }
    }
}
