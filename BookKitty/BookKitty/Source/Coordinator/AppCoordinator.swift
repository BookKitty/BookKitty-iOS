//
// AppCoordinator.swift
// BookKitty
//
// Created by 권승용 on 1/23/25.
//
import UIKit

final class AppCoordinator: Coordinator {
    // MARK: - Properties

    // MARK: - Internal

    weak var finishDelegate: CoordinatorFinishDelegate?
    var childCoordinators: [Coordinator] = []
    let navigationController: UINavigationController

    // MARK: - Lifecycle

    init(_ navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    // MARK: - Functions

    func start() { showCustomTabBarFlow() }
}

extension AppCoordinator {
    private func showCustomTabBarFlow() {
        let tabBarCoordinator = TabBarCoordinator(navigationController)
        navigationController.navigationBar.isHidden = true
        addChildCoordinator(tabBarCoordinator)
        tabBarCoordinator.start()
    }
}
