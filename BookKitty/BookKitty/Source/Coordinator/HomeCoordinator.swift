//
//  HomeCoordinator.swift
//  BookKitty
//
//  Created by 전성규 on 1/26/25.
//

import RxSwift
import UIKit

protocol HomeCoordinator: Coordinator {
    var homeViewController: HomeViewController { get set }
}

final class DefaultHomeCoordinator: Coordinator {
    // MARK: - Properties

    // MARK: - Internal

    var childCoordinators: [Coordinator] = []

    var navigationController: UINavigationController
    var homeViewController: HomeViewController

    var homeViewModel: HomeViewModel
    var finishDelegate: (any CoordinatorFinishDelegate)?

    // MARK: - Private

    private let disposeBag = DisposeBag()

    // MARK: - Lifecycle

    init(_ navigationController: UINavigationController) {
        self.navigationController = navigationController
        let repository = LocalBookRepository()
        homeViewModel = HomeViewModel(
            bookRepository: repository
        )
        homeViewController = HomeViewController(viewModel: homeViewModel)
    }

    // MARK: - Functions

    func start() { showHomeScreen() }
}

extension DefaultHomeCoordinator {
    /// 책 목록 화면 표시
    ///
    /// 책 목록 화면을 생성하고 ViewModel과 ViewController를 연결
    /// 사용자가 책을 선택하면 책 상세 화면으로 이동
    private func showHomeScreen() {
        homeViewModel.navigateToBookDetail
            .withUnretained(self)
            .subscribe(onNext: { coordinator, book in
                let bookDetailCoordinator = DefaultBookDetailCoordinator(
                    coordinator
                        .navigationController
                )

                coordinator.addChildCoordinator(bookDetailCoordinator)
                bookDetailCoordinator.finishDelegate = self
                bookDetailCoordinator.start(with: book)
            })
            .disposed(by: disposeBag)

        navigationController.pushViewController(homeViewController, animated: true)
    }
}

extension DefaultHomeCoordinator: CoordinatorFinishDelegate {
    func coordinatorDidFinish(childCoordinator: any Coordinator) {
        childCoordinators.removeAll { $0 === childCoordinator }
        navigationController.popViewController(animated: true)
    }
}
