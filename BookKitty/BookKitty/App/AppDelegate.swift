//
//  AppDelegate.swift
//  BookKitty
//
//  Created by 권승용 on 1/22/25.
//

import DesignSystem
import FirebaseCore
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    // MARK: - Properties

    var window: UIWindow?
    var appCoordinator: AppCoordinator?

    // MARK: - Functions

    func application(
        _: UIApplication,
        didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // 폰트 등록 및 Firebase 설정
        UIFont.registerFonts()
        FirebaseApp.configure()

        // 윈도우 및 네비게이션 컨트롤러 설정
        window = UIWindow(frame: UIScreen.main.bounds)
        let navigationController = UINavigationController()

        // 온보딩 완료 여부 확인
        let isOnboardingCompleted = UserDefaults.standard.bool(forKey: "isOnboardingCompleted")

        if !isOnboardingCompleted {
            // 온보딩 화면 표시
            let onboardingViewController = OnboardingViewController()
            onboardingViewController.onFinish = { [weak self] in
                self?.startMainFlow()
            }
            navigationController.viewControllers = [onboardingViewController]
        } else {
            // 메인 화면 표시
            startMainFlow()
        }

        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()

        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(
        _: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options _: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        UISceneConfiguration(
            name: "Default Configuration",
            sessionRole: connectingSceneSession.role
        )
    }

    private func startMainFlow() {
        guard let navigationController = window?.rootViewController as? UINavigationController
        else {
            return
        }
        appCoordinator = AppCoordinator(navigationController)
        appCoordinator?.start()
    }
}
