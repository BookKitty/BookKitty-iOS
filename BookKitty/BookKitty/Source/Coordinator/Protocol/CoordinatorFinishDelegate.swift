//
// CoordinatorFinishDelegate.swift
// BookKitty
//
// Created by 전성규 on 2/6/25.
//

import Foundation

protocol CoordinatorFinishDelegate: AnyObject {
    func coordinatorDidFinish(childCoordinator: Coordinator)
}
