//
//  AddBookCoordinator.swift
//  BookKitty
//
//  Created by 반성준 on 1/31/25.
//

import RxCocoa
import RxRelay
import RxSwift
import UIKit

protocol AddBookCoordinator: Coordinator {
    var addBookViewController: AddBookViewController { get }
}

final class DefaultAddBookCoordinator: AddBookCoordinator {
    // MARK: Lifecycle

    // MARK: - Init

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

    // MARK: - Start

    func start() {
        setupBindings()
        navigationController.pushViewController(addBookViewController, animated: true)
    }

    // MARK: Private

    private let disposeBag = DisposeBag()

    private func setupBindings() {
        let manualTitleRelay = PublishRelay<String>()

        let input = AddBookViewModel.Input(
            captureButtonTapped: addBookViewController.captureButton.rx.tap.asObservable(),
            manualAddButtonTapped: manualTitleRelay.asObservable(),
            confirmButtonTapped: addBookViewController.confirmButton.rx.tap.asObservable()
        )

        let output = addBookViewModel.transform(input)

        // ✅ 수동 입력 버튼 클릭 시 팝업 표시
        addBookViewController.manualAddButton.rx.tap
            .bind { [weak self] in self?.showManualTitleInput(relay: manualTitleRelay) }
            .disposed(by: disposeBag)

        // ✅ `navigateToReviewAddBook`이 `[Book]`을 반환하도록 수정
        output.navigateToReviewAddBook
            .bind { [weak self] bookList in self?.showReviewAddBookScene(bookList: bookList) }
            .disposed(by: disposeBag)
    }

    // MARK: - Navigation

    private func showManualTitleInput(relay: PublishRelay<String>) {
        let alert = UIAlertController(
            title: "책 제목 입력",
            message: "책 제목을 입력해주세요.",
            preferredStyle: .alert
        )

        alert.addTextField()

        let addAction = UIAlertAction(title: "추가", style: .default) { _ in
            if let title = alert.textFields?.first?.text, !title.isEmpty {
                relay.accept(title) // ✅ `relay`를 통해 ViewModel로 전달
            }
        }
        let cancelAction = UIAlertAction(title: "취소", style: .cancel)

        alert.addAction(addAction)
        alert.addAction(cancelAction)
        addBookViewController.present(alert, animated: true)
    }

    private func showReviewAddBookScene(bookList: [Book]) {
        let reviewViewModel = ReviewAddBookViewModel(initialBookList: bookList)
        let reviewViewController = ReviewAddBookViewController(viewModel: reviewViewModel)

        // ✅ `navigateToBookListRelay`을 이용하여 화면 이동 후 종료 처리
        reviewViewModel.navigateToBookListRelay
            .bind { [weak self] in self?.finish() }
            .disposed(by: disposeBag)

        navigationController.pushViewController(reviewViewController, animated: true)
    }

    private func finish() {
        if let tabBarController = navigationController.viewControllers
            .first(where: { $0 is TabBarController }) {
            navigationController.popToViewController(tabBarController, animated: true)
            parentCoordinator?.childCoordinators.removeAll { $0 === self }
        }
    }
}
