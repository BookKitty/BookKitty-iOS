//
// BookCoordinator.swift
// BookKitty
//
// Created by 전성규 on 1/27/25.
//
import RxSwift
import UIKit

/// 책 관련 화면 흐름을 관리하는 Coordinator
///
/// `BookCoordinator`는 책 목록과 책 상세 화면 간의 흐름을 관리
final class BookCoordinator: Coordinator {
    // MARK: Lifecycle

    init(_ navigationController: UINavigationController) {
        self.navigationController = navigationController
        myLibraryViewModel = MyLibraryViewModel(bookRepository: MockBookRepository())
        myLibraryViewController = MyLibraryViewController(viewModel: myLibraryViewModel)
    }

    // MARK: Internal

    weak var finishDelegate: CoordinatorFinishDelegate?
    var parentCoordinator: Coordinator?
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    var myLibraryViewController: MyLibraryViewController
    var myLibraryViewModel: MyLibraryViewModel

    func start() { showMyLibraryScene() }

    // MARK: Private

    private let disposeBag = DisposeBag()
}

extension BookCoordinator {
    /// 책 목록 화면 표시
    ///
    /// 책 목록 화면을 생성하고 ViewModel과 ViewController를 연결
    /// 사용자가 책을 선택하면 책 상세 화면으로 이동
    private func showMyLibraryScene() {
        // 책 상세 화면으로 이동 이벤트 처리
        myLibraryViewModel
            .navigateToBookDetail
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                owner.showBookDetailScreen()
            }).disposed(by: disposeBag)
    }

    /// 책 상세 화면 표시
    ///
    /// 책 상세 화면을 생성하고 ViewModel과 ViewController를 연결
    private func showBookDetailScreen() {
        let bookDetailViewModel = BookDetailViewModel()
        let bookDetailViewController = BookDetailViewController(viewModel: bookDetailViewModel)
        navigationController.pushViewController(bookDetailViewController, animated: true)
    }
}
