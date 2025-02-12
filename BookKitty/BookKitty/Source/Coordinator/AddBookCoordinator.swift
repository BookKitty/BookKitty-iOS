//
// AddBookCoordinator.swift
// BookKitty
//
// Created by 반성준 on 1/31/25.
//
import RxCocoa
import RxRelay
import RxSwift
import UIKit

final class AddBookCoordinator: Coordinator {
    // MARK: - Properties

    // MARK: - Internal

    weak var finishDelegate: CoordinatorFinishDelegate?

    var parentCoordinator: Coordinator?
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController

    var addBookViewController: AddBookViewController
    var addBookViewModel: AddBookViewModel

    // MARK: - Private

    private let disposeBag = DisposeBag()
    private let confirmButtonRelay =
        PublishRelay<Void>() // :흰색_확인_표시: `confirmButton` 이벤트를 위한 Relay 추가

    // MARK: - Lifecycle

    init(_ navigationController: UINavigationController) {
        self.navigationController = navigationController
        addBookViewModel = AddBookViewModel()
        addBookViewController = AddBookViewController(viewModel: addBookViewModel)
    }

    // MARK: - Functions

    // MARK: - Start

    func start() {
        showAddBookScreen()
    }
}

extension AddBookCoordinator {
    private func showAddBookScreen() {
        addBookViewModel.navigateBackRelay
            .withUnretained(self)
            .bind(onNext: { owner, _ in
                owner.finish()
            }).disposed(by: disposeBag)

        addBookViewModel.navigateToReviewRelay
            .withUnretained(self)
            .subscribe(onNext: { coordinator, bookList in
                coordinator.showReviewBookScene(bookList: bookList)
            }).disposed(by: disposeBag)

        navigationController.pushViewController(addBookViewController, animated: true)
    }

    private func showReviewBookScene(bookList: [Book]) {
        let reviewViewModel = ReviewAddBookViewModel(initialBookList: bookList)

        reviewViewModel.navigateBackRelay
            .withUnretained(self)
            .bind(onNext: { owner, _ in
                owner.navigationController.popViewController(animated: true)
            }).disposed(by: disposeBag)

        reviewViewModel.navigateToBookListRelay
            .bind { [weak self] in
                self?.finish()
            }
            .disposed(by: disposeBag)

        let reviewViewController = ReviewAddBookViewController(viewModel: reviewViewModel)

        navigationController.pushViewController(reviewViewController, animated: true)
    }
}
