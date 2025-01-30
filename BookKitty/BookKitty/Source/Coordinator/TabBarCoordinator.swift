//
//  TabBarCoordinator.swift
//  BookKitty
//
//  Created by 전성규 on 1/26/25.
//

import RxSwift
import UIKit

enum TabBarItemType: CaseIterable {
    case home
    case question
    case book

    // MARK: Lifecycle

    init?(index: Int) {
        switch index {
        case 0: self = .home
        case 1: self = .question
        case 2: self = .book
        default: return nil
        }
    }

    // MARK: Internal

    func toInt() -> Int {
        switch self {
        case .home: return 0
        case .question: return 1
        case .book: return 2
        }
    }

    func toKrName() -> String {
        switch self {
        case .home: return "홈"
        case .question: return "질문"
        case .book: return "책"
        }
    }

    func toIconName() -> String {
        switch self {
        case .home: return "house"
        case .question: return "star"
        case .book: return "book"
        }
    }
}

final class TabBarCoordinator: Coordinator {
    // MARK: Lifecycle

    init(_ navigationController: UINavigationController) {
        self.navigationController = navigationController
        tabBarViewModel = TabBarViewModel()
        tabBarController = TabBarController(viewModel: tabBarViewModel)
    }

    // MARK: Internal

    var parentCoordinator: Coordinator?
    var navigationController: UINavigationController
    var tabBarController: TabBarController
    var tabBarViewModel: TabBarViewModel
    var childCoordinators: [Coordinator] = []

    func start() {
        let pages = TabBarItemType.allCases
        let tabBarItems = pages.map { createTabBarItem(of: $0) }
        let controllers = tabBarItems.map { createTabNavigationController(tabBarItem: $0) }
        _ = controllers.map { startTabCoordinator(tabNavigationController: $0) }
        configureTabBarController(tabNavigationControllers: controllers)
        addTabBarController()
    }

    // MARK: Private

    private let disposeBag = DisposeBag()

    /// TabBarItem 생성
    ///
    /// - Parameter page: 생성할 탭바 항목에 대한 타입
    /// - Returns: UITabBarItem
    private func createTabBarItem(of page: TabBarItemType) -> UITabBarItem {
        UITabBarItem(
            title: page.toKrName(),
            image: UIImage(systemName: page.toIconName()),
            tag: page.toInt()
        )
    }

    /// UINavigationController 생성
    ///
    /// - Parameter tabBarItem: 생성한 UITabBarItem
    /// - Returns: UITabBarItem을 설정한 UINavigationController
    private func createTabNavigationController(tabBarItem: UITabBarItem) -> UINavigationController {
        let tabNavigationController = UINavigationController()
        tabNavigationController.tabBarItem = tabBarItem

        return tabNavigationController
    }

    /// 각 탭의 Coordinator 시작
    ///
    /// - Parameter tabNavigationController: 탭바에 연결된 UINavigationController
    private func startTabCoordinator(tabNavigationController: UINavigationController) {
        let tabBarItemTag = tabNavigationController.tabBarItem.tag
        guard let tabBarItemType = TabBarItemType(index: tabBarItemTag) else {
            return
        }

        switch tabBarItemType {
        case .home:
            let homeCoordinator = DefaultHomeCoordinator(tabNavigationController)
            addChildCoordinator(homeCoordinator)
            homeCoordinator.start()
        case .question:
            let questionCoordinator = QuestionCoordinator(tabNavigationController)
            addChildCoordinator(questionCoordinator)
            questionCoordinator.parentCoordinator = self
            questionCoordinator.start()
        case .book:
            let bookCoordinator = MyLibraryCoordinator(tabNavigationController)
            addChildCoordinator(bookCoordinator)
            bookCoordinator.parentCoordinator = self
            bookCoordinator.start()
        }
    }

    /// TabBarController 설정
    ///
    /// - Parameter tabNavigationControllers: 탭에 연결된 네비게이션 컨트롤러 배열
    private func configureTabBarController(tabNavigationControllers: [UIViewController]) {
        tabBarController.setViewControllers(tabNavigationControllers, animated: false)
        tabBarController.selectedIndex = TabBarItemType.home.toInt()
    }

    /// TabBarController를 NavigationController에 추가
    private func addTabBarController() {
        navigationController.pushViewController(tabBarController, animated: true)
    }
}
