//
//  SceneDelegate.swift
//  BookKitty
//
//  Created by 권승용 on 1/22/25.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    // MARK: - Properties

    var window: UIWindow?
    var appCoordinator: AppCoordinator?

    // MARK: - Functions

    func scene(
        _ scene: UIScene,
        willConnectTo _: UISceneSession,
        options _: UIScene.ConnectionOptions
    ) {
        guard let windowScene = (scene as? UIWindowScene) else {
            return
        }
        let navigationController = UINavigationController()

        window = UIWindow(windowScene: windowScene)

        // 개발 중 온보딩 화면을 항상 표시하려면 아래 줄을 활성화
        UserDefaults.standard.removeObject(forKey: "isOnboardingCompleted")
        UserDefaults.standard.set(false, forKey: "isOnboardingCompleted")

        // 온보딩 완료 여부 확인
        let isOnboardingCompleted = UserDefaults.standard.bool(forKey: "isOnboardingCompleted")

        if !isOnboardingCompleted {
            // 온보딩 화면 표시
            let onboardingViewController = OnboardingViewController()
            onboardingViewController.onFinish = { [weak self] in
                UserDefaults.standard.set(true, forKey: "isOnboardingCompleted")
                self?.startMainFlow()
            }
            navigationController.viewControllers = [onboardingViewController]
        } else {
            // 메인 화면 표시
            startMainFlow(with: navigationController)
        }

        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
    }

    private func startMainFlow(with navigationController: UINavigationController? = nil) {
        let navController = navigationController ??
            (window?.rootViewController as? UINavigationController)
        guard let nav = navController else {
            return
        }

        appCoordinator = AppCoordinator(nav)
        appCoordinator?.start()
    }

    // 최상위 계층(AppDelegate 또는 SceneDelegate)에서 모든 의존성을 생성 및 주입
    // 추후 DI Container를 활용, 의존성 생성 책임을 분리
    //        let persistence = BookCoreDataManager()
    //        let repository = DefaultBookRepository(bookPersistence: persistence)
    //        let service = AddBookService(bookRepository: repository)
    //        let viewModel = GuideViewModel(addBookService: service, bookRepository:
    //        repository)
    //        GuideViewController(viewModel: viewModel)
}
