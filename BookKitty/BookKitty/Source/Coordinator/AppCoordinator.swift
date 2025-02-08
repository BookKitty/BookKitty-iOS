//
// AppCoordinator.swift
// BookKitty
//
// Created by 권승용 on 1/23/25.
//
import UIKit

final class AppCoordinator: Coordinator {
    // MARK: - Lifecycle

    init(_ navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    // MARK: - Internal

    weak var finishDelegate: CoordinatorFinishDelegate?
    var parentCoordinator: Coordinator?
    var childCoordinators: [Coordinator] = []
    let navigationController: UINavigationController

    func start() { showCustomTabBarFlow() }
}

extension AppCoordinator {
    private func showCustomTabBarFlow() {
        let tabBarCoordinator = TabBarCoordinator(navigationController)
        navigationController.navigationBar.isHidden = true
        addChildCoordinator(tabBarCoordinator)
        tabBarCoordinator.parentCoordinator = self
        tabBarCoordinator.start()
    }
}
