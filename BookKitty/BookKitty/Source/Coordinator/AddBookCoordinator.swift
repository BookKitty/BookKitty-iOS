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

    weak var finishDelegate: CoordinatorFinishDelegate?
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
    private let confirmButtonRelay =
        PublishRelay<Void>() // :흰색_확인_표시: `confirmButton` 이벤트를 위한 Relay 추가

    private func setupBindings() {
        let manualTitleRelay = PublishRelay<String>()
        let input = AddBookViewModel.Input(
            captureButtonTapped: addBookViewController.captureButton.rx.tap.asObservable(),
            // :흰색_확인_표시: `BaseCameraViewController`의 captureButton 사용
            manualAddButtonTapped: manualTitleRelay.asObservable(),
            confirmButtonTapped: confirmButtonRelay
                .asObservable() // :흰색_확인_표시: `confirmButton`을 Relay로 변경
        )
        let output = addBookViewModel.transform(input)
        // :흰색_확인_표시: 수동 입력 버튼 클릭 시 팝업 표시
        addBookViewController.navigationItem.rightBarButtonItem?.rx.tap
            .bind { [weak self] in self?.showManualTitleInput(relay: manualTitleRelay) }
            .disposed(by: disposeBag)
        // :흰색_확인_표시: `navigateToReviewAddBook`이 `[Book]`을 반환하도록 수정
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
                relay.accept(title) // :흰색_확인_표시: `relay`를 통해 ViewModel로 전달
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
        // :흰색_확인_표시: `navigateToBookListRelay`을 이용하여 화면 이동 후 종료 처리
        reviewViewModel.navigateToBookListRelay
            .bind { [weak self] in self?.finish() }
            .disposed(by: disposeBag)
        navigationController.pushViewController(reviewViewController, animated: true)
    }
}
