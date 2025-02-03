//
//  TabBarCoordinator.swift
//  BookKitty
//
//  Created by 전성규 on 1/30/25.
//

import RxSwift
import UIKit

final class TabBarCoordinator: Coordinator {
    // MARK: Lifecycle

    init(_ navigationController: UINavigationController) {
        self.navigationController = navigationController
        tabBarViewModel = TabBarViewModel()
        tabBarController = TabBarController(viewModel: tabBarViewModel)
    }

    // MARK: Internal

    var parentCoordinator: Coordinator?
    var childCoordinators: [Coordinator] = []

    var navigationController: UINavigationController
    var tabBarController: TabBarController

    var tabBarViewModel: TabBarViewModel

    func start() {
        // Tab에 해당하는 Coordinator 생성
        let homeCoordinator = DefaultHomeCoordinator(navigationController)
        let qnaCoordinator = DefaultQuestionCoordinator(navigationController)
        let bookCoordinator = BookCoordinator(navigationController)

        // childCoordinators에 각 Tab에 해당하는 Coordinator 등록
        addChildCoordinator(homeCoordinator, qnaCoordinator, bookCoordinator)

        // 각 Coordinator의 부모 코디네이터를 TabBarCoordinator로 지정
        homeCoordinator.parentCoordinator = self
        qnaCoordinator.parentCoordinator = self
        bookCoordinator.parentCoordinator = self

        // 각 Coordinator start()메서드 호출
        homeCoordinator.start()
        qnaCoordinator.start()
        bookCoordinator.start()

        // TabBarController의 controllers 프로퍼티에 각 coordinator의 rootViewController 등록
        tabBarController.setViewControllers(
            homeCoordinator.homeViewController,
            qnaCoordinator.questionHistoryViewController,
            bookCoordinator.bookListViewController
        )

        tabBarViewModel.navigateToAddBook
            .withUnretained(self)
            .bind(onNext: { owner, _ in
                owner.showAddBookFlow()
            }).disposed(by: disposeBag)

        navigationController.pushViewController(tabBarController, animated: true)
    }

    // MARK: Private

    private let disposeBag = DisposeBag()
}

extension TabBarCoordinator {
    private func showAddBookFlow() {
        let addBookCoordinator = DefaultAddBookCoordinator(navigationController)

        addChildCoordinator(addBookCoordinator)
        addBookCoordinator.parentCoordinator = self
        addBookCoordinator.start()
    }
}
