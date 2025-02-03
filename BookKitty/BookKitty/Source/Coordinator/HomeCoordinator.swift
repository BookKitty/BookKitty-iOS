//
//  HomeCoordinator.swift
//  BookKitty
//
//  Created by 전성규 on 1/26/25.
//

import UIKit

protocol HomeCoordinator: Coordinator {
    var homeViewController: HomeViewController { get set }
}

final class DefaultHomeCoordinator: Coordinator {
    // MARK: Lifecycle

    init(_ navigationController: UINavigationController) {
        self.navigationController = navigationController
        homeViewController = HomeViewController()
    }

    // MARK: Internal

    var parentCoordinator: Coordinator?
    var childCoordinators: [Coordinator] = []

    var navigationController: UINavigationController
    var homeViewController: HomeViewController

    func start() {
        navigationController.pushViewController(homeViewController, animated: true)
    }
}
