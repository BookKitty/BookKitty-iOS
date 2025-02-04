//
//  MyLibraryCoordinator.swift
//  BookKitty
//
//  Created by 전성규 on 1/27/25.
//

import RxSwift
import UIKit

/// 책 관련 화면 흐름을 관리하는 Coordinator
///
/// `MyLibraryCoordinator`는 책 목록과 책 상세 화면 간의 흐름을 관리
final class MyLibraryCoordinator: Coordinator {
    // MARK: Lifecycle

    init(_ navigationController: UINavigationController) {
        self.navigationController = navigationController
        let repository = MockBookRepository()
        bookListViewModel = MyLibraryViewModel(bookRepository: repository)
        bookListViewController = MyLibraryViewController(viewModel: bookListViewModel)
    }

    // MARK: Internal

    var parentCoordinator: Coordinator?
    var childCoordinators: [Coordinator] = []

    var navigationController: UINavigationController
    var bookListViewController: MyLibraryViewController

    var bookListViewModel: MyLibraryViewModel

    func start() { showMyLibraryScreen() }

    // MARK: Private

    private let disposeBag = DisposeBag()
}

extension MyLibraryCoordinator {
    /// 책 목록 화면 표시
    ///
    /// 책 목록 화면을 생성하고 ViewModel과 ViewController를 연결
    /// 사용자가 책을 선택하면 책 상세 화면으로 이동
    private func showMyLibraryScreen() {
        let bookRepository = MockBookRepository()
        let myLibraryViewModel = MyLibraryViewModel(bookRepository: bookRepository)
        let myLibraryViewController = MyLibraryViewController(viewModel: myLibraryViewModel)

        // 책 상세 화면으로 이동 이벤트 처리
        myLibraryViewModel.navigateToBookDetail
            .withUnretained(self)
            .subscribe(onNext: { coordinator, book in
                coordinator.showBookDetailScreen(with: book)
            })
            .disposed(by: disposeBag)

        navigationController.pushViewController(myLibraryViewController, animated: true)
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
