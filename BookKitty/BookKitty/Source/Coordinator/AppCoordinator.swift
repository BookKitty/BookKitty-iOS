//
//  AppCoordinator.swift
//  BookKitty
//
//  Created by 권승용 on 1/23/25.
//

import UIKit

final class AppCoordinator: Coordinator {
    // MARK: Lifecycle

    init(_ navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    // MARK: Internal

    var parentCoordinator: Coordinator?
    let navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []

    func start() { showTabBarFlow() }
}

extension AppCoordinator {
    /// TabBar 흐름 시작
    ///
    /// TabBarCoordinator를 초기화하고 화면을 표시
    private func showTabBarFlow() {
        let tabBarCoordinator = TabBarCoordinator(navigationController)
        navigationController.navigationBar.isHidden = true
        addChildCoordinator(tabBarCoordinator)
        tabBarCoordinator.parentCoordinator = self
        tabBarCoordinator.start()
    }
}
