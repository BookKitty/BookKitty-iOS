//
// AddBookCoordinator.swift
// BookKitty
//
// Created by 반성준 on 1/31/25.
//
import BookMatchKit
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

    // MARK: - Lifecycle

    init(_ navigationController: UINavigationController) {
        self.navigationController = navigationController

        let repository = LocalBookRepository()

        addBookViewModel = AddBookViewModel(
            bookRepository: repository
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

        navigationController.pushViewController(addBookViewController, animated: true)
    }

    private func showReviewBookScene(bookList: [Book]) { // ✅ bookList 파라미터 유지
        let bookMatchKit = BookMatchKit(
            naverClientId: "your_client_id",
            naverClientSecret: "your_client_secret"
        ) // ✅ BookMatchKit 인스턴스 생성

        let reviewViewModel = ReviewAddBookViewModel(
            initialBookList: bookList, // ✅ bookList 전달
            bookMatchKit: bookMatchKit
        ) // ✅ reviewViewModel 생성

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
