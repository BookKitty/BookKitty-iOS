//
// Coordinator.swift
// BookKitty
//
// Created by 전성규 on 1/26/25.
//
import UIKit

protocol Coordinator: AnyObject {
    var finishDelegate: CoordinatorFinishDelegate? { get set }
//    /// 현재 Coordinator를 소유한 상위 Coordinator
//    var parentCoordinator: Coordinator? { get }
    /// 현재 Coordinator가 관리하는 하위 Coordinators의 배열입니다.
    var childCoordinators: [Coordinator] { get set }
    var navigationController: UINavigationController { get }
    /// Coordinator의 시작 지점
    ///
    /// Coordinator를 초기화하고, 첫 화면을 설정하거나 필요한 동작을 정의하는 메서드
    func start()
    func finish()
}

extension Coordinator {
    func addChildCoordinator(_ coordinator: Coordinator...) {
        childCoordinators.append(contentsOf: coordinator)
    }

    func finish() {
        childCoordinators.removeAll()
        finishDelegate?.coordinatorDidFinish(childCoordinator: self)
    }
}
