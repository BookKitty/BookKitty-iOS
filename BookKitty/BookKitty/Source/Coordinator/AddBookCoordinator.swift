//
//  AddBookCoordinator.swift
//  BookKitty
//
//  Created by 반성준 on 1/31/25.
//

import RxCocoa
import RxRelay // ✅ PublishRelay 사용을 위해 추가
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

// MARK: - Navigation Logic

extension DefaultAddBookCoordinator {
    private func showAddBookScene() {
        let manualTitleRelay = PublishRelay<String>() // ✅ 책 제목을 직접 입력받는 Relay 추가

        let input = AddBookViewModel.Input(
            captureButtonTapped: addBookViewController.captureButton.rx.tap.asObservable(),
            manualAddButtonTapped: manualTitleRelay.asObservable(), // ✅ 입력된 제목 전달
            confirmButtonTapped: addBookViewController.confirmButton.rx.tap.asObservable()
        )

        let output = addBookViewModel.transform(input)

        // ✅ 사용자가 제목을 직접 입력하면 relay에 전달
        addBookViewController.manualAddButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.showManualTitleInput(relay: manualTitleRelay)
            })
            .disposed(by: disposeBag)

        // ✅ 책 추가 완료 후 이동
        output.navigateToReviewAddBook
            .subscribe(onNext: { [weak self] bookList in
                self?.showReviewAddBookScene(bookList: bookList)
            })
            .disposed(by: disposeBag)

        navigationController.pushViewController(addBookViewController, animated: true)
    }

    private func showManualTitleInput(relay: PublishRelay<String>) {
        let alert = UIAlertController(
            title: "책 제목 입력",
            message: "책 제목을 입력해주세요.",
            preferredStyle: .alert
        )
        alert.addTextField()

        let addAction = UIAlertAction(title: "추가", style: .default) { _ in
            if let title = alert.textFields?.first?.text, !title.isEmpty {
                relay.accept(title)
            }
        }
        let cancelAction = UIAlertAction(title: "취소", style: .cancel)

        alert.addAction(addAction)
        alert.addAction(cancelAction)
        addBookViewController.present(alert, animated: true)
    }

    private func showReviewAddBookScene(bookList: [String]) {
        let reviewAddBookViewModel = ReviewAddBookViewModel(initialBookList: bookList)
        let reviewAddBookViewController =
            ReviewAddBookViewController(viewModel: reviewAddBookViewModel)

        // ✅ `navigateToBookListRelay`를 `internal`로 변경하여 접근 가능
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
