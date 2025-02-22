//
// TabBarCoordinator.swift
// BookKitty
//
// Created by 전성규 on 1/30/25.
//
import RxSwift
import UIKit

final class TabBarCoordinator: Coordinator {
    // MARK: - Properties

    // MARK: - Internal

    weak var finishDelegate: CoordinatorFinishDelegate?
    var parentCoordinator: Coordinator?
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    var tabBarController: TabBarController
    var tabBarViewModel: TabBarViewModel

    // MARK: - Private

    private let disposeBag = DisposeBag()

    // MARK: - Lifecycle

    init(_ navigationController: UINavigationController) {
        self.navigationController = navigationController
        tabBarViewModel = TabBarViewModel()
        tabBarController = TabBarController(viewModel: tabBarViewModel)
    }

    // MARK: - Functions

    func start() {
        // Tab에 해당하는 Coordinator 생성
        let homeCoordinator = DefaultHomeCoordinator(navigationController)
        let qnaCoordinator = DefaultQuestionCoordinator(navigationController)
        let bookCoordinator = MyLibraryCoordinator(navigationController)

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
            bookCoordinator.myLibraryViewController
        )
        tabBarViewModel.navigateToAddBook
            .withUnretained(self)
            .bind(onNext: { owner, _ in
                owner.showAddBookFlow()
            }).disposed(by: disposeBag)

        tabBarViewModel.navigateToAddQuestion
            .withUnretained(self)
            .bind(onNext: { owner, _ in
                owner.showAddQuestionFlow()
            }).disposed(by: disposeBag)
        navigationController.pushViewController(tabBarController, animated: true)
    }
}

extension TabBarCoordinator {
    private func showAddBookFlow() {
        let addBookCoordinator = AddBookCoordinator(navigationController)
        addChildCoordinator(addBookCoordinator)
        addBookCoordinator.finishDelegate = self
        addBookCoordinator.parentCoordinator = self
        addBookCoordinator.start()
    }

    private func showAddQuestionFlow() {
        let addQuestionCoordinator = AddQuestionCoordinator(navigationController)
        addChildCoordinator(addQuestionCoordinator)
        addQuestionCoordinator.finishDelegate = self
        addQuestionCoordinator.parentCoordinator = self
        addQuestionCoordinator.start()
    }
}

extension TabBarCoordinator: CoordinatorFinishDelegate {
    func coordinatorDidFinish(childCoordinator: Coordinator) {
        childCoordinators.removeAll { $0 === childCoordinator }
        if childCoordinator is AddQuestionCoordinator {
            tabBarController.tabBar.selectedIndex.accept(1)
        } else if childCoordinator is AddBookCoordinator {
            tabBarController.tabBar.selectedIndex.accept(2)
        }
        navigationController.popViewController(animated: true)
    }
}
