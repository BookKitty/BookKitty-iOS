//
// AddBookCoordinator.swift
// BookKitty
//
// Created by 반성준 on 1/31/25.
//
import BookOCRKit
import RxCocoa
import RxRelay
import RxSwift
import UIKit

final class AddBookCoordinator: Coordinator {
    // MARK: - Properties

    weak var finishDelegate: CoordinatorFinishDelegate?
    var parentCoordinator: Coordinator?
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController

    var addBookViewController: AddBookViewController
    var addBookViewModel: AddBookViewModel

    // MARK: - Private

    private let disposeBag = DisposeBag()
    private let confirmButtonRelay = PublishRelay<Void>()
    private let repository = LocalBookRepository()
    private let bookOCRKit = BookOCRKit(
        naverClientId: Environment().naverClientID,
        naverClientSecret: Environment().naverClientSecret
    )

    // MARK: - Lifecycle

    init(_ navigationController: UINavigationController) {
        self.navigationController = navigationController

        addBookViewModel = AddBookViewModel(
            bookRepository: repository,
            bookOCRKit: bookOCRKit
        )
        addBookViewController = AddBookViewController(
            viewModel: addBookViewModel
        ) // ✅ 올바르게 전달
    }

    // MARK: - Functions

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

        addBookViewModel.navigateToAddBookByText
            .withUnretained(self)
            .subscribe { owner, _ in
                owner.showAddBookByTitleScreen()
            }
            .disposed(by: disposeBag)

        navigationController.pushViewController(addBookViewController, animated: true)
    }

    private func showAddBookByTitleScreen() {
        let addBookByTitleViewModel = AddBookByTitleViewModel(
            bookRepository: repository,
            bookOcrKit: bookOCRKit
        )
        let addBookByTitleViewController = AddBookByTitleViewController(
            viewModel: addBookByTitleViewModel
        )

        addBookByTitleViewModel.navigationBackRelay
            .withUnretained(self)
            .bind { owner, _ in
                owner.navigationController.popViewController(animated: true)
            }
            .disposed(by: disposeBag)

        addBookByTitleViewModel.navigationAfterBookAddedRelay
            .withUnretained(self)
            .bind { owner, _ in
                let viewControllers: [UIViewController] = owner.navigationController
                    .viewControllers as [UIViewController]
                owner.navigationController.popToViewController(
                    viewControllers[viewControllers.count - 3],
                    animated: true
                )
                owner.finish()
            }
            .disposed(by: disposeBag)

        navigationController.pushViewController(addBookByTitleViewController, animated: true)
    }
}
