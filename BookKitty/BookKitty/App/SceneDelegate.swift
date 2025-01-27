//
//  SceneDelegate.swift
//  BookKitty
//
//  Created by 권승용 on 1/22/25.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo _: UISceneSession,
        options _: UIScene.ConnectionOptions
    ) {
        guard let windowScene = (scene as? UIWindowScene) else {
            return
        }
        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = HomeViewController()
        window?.makeKeyAndVisible()

        // 최상위 계층(AppDelegate 또는 SceneDelegate)에서 모든 의존성을 생성 및 주입
        // 추후 DI Container를 활용, 의존성 생성 책임을 분리
        //        let persistence = BookCoreDataManager()
        //        let repository = DefaultBookRepository(bookPersistence: persistence)
        //        let service = AddBookService(bookRepository: repository)
        //        let viewModel = GuideViewModel(addBookService: service, bookRepository:
        //        repository)
        //        GuideViewController(viewModel: viewModel)
    }
}
