//
//  HomeCoordinator.swift
//  BookKitty
//
//  Created by 전성규 on 1/26/25.
//

import RxSwift
import UIKit

protocol HomeCoordinator: Coordinator {
    var homeViewController: HomeViewController { get set }
}

final class DefaultHomeCoordinator: Coordinator {
    // MARK: - Lifecycle

    init(_ navigationController: UINavigationController) {
        self.navigationController = navigationController
        let repository = MockBookRepository()
        homeViewModel = HomeViewModel(bookRepository: repository)
        homeViewController = HomeViewController(viewModel: homeViewModel)
    }

    // MARK: - Internal

    var parentCoordinator: Coordinator?
    var childCoordinators: [Coordinator] = []

    var navigationController: UINavigationController
    var homeViewController: HomeViewController

    var homeViewModel: HomeViewModel
    var finishDelegate: (any CoordinatorFinishDelegate)?

    func start() { showHomeScreen() }

    // MARK: - Private

    private let disposeBag = DisposeBag()
}

extension DefaultHomeCoordinator {
    /// 책 목록 화면 표시
    ///
    /// 책 목록 화면을 생성하고 ViewModel과 ViewController를 연결
    /// 사용자가 책을 선택하면 책 상세 화면으로 이동
    private func showHomeScreen() {
        let bookRepository = MockBookRepository()
        let homeViewModel = HomeViewModel(bookRepository: bookRepository)
        let homeViewController = HomeViewController(viewModel: homeViewModel)

        // 책 상세 화면으로 이동 이벤트 처리
        homeViewModel.navigateToBookDetail
            .withUnretained(self)
            .subscribe(onNext: { coordinator, book in
                coordinator.showBookDetailScreen(with: book)
            })
            .disposed(by: disposeBag)

        navigationController.pushViewController(homeViewController, animated: true)
    }

    /// 책 상세 화면 표시
    ///
    /// 책 상세 화면을 생성하고 ViewModel과 ViewController를 연결
    /// 탭바를 숨기고 화면을 네비게이션 스택에 추가
    /// - Parameter book: 책 상세 화면에서 표시할 Book 정보가 담긴 구조체
    private func showBookDetailScreen(with _: Book) {
        let bookDetailViewModel = BookDetailViewModel()
        let bookDetailViewController = BookDetailViewController(viewModel: bookDetailViewModel)

        navigationController.pushViewController(bookDetailViewController, animated: true)
    }
}
