//
// MyLibraryCoordinator.swift
// BookKitty
//
// Created by 전성규 on 1/27/25.
//
import RxSwift
import UIKit

/// 책 관련 화면 흐름을 관리하는 Coordinator
///
/// `MyLibraryCoordinator`는 책 목록과 책 상세 화면 간의 흐름을 관리
final class MyLibraryCoordinator: Coordinator {
    // MARK: - Properties

    // MARK: - Internal

    weak var finishDelegate: CoordinatorFinishDelegate?
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    var myLibraryViewController: MyLibraryViewController
    var myLibraryViewModel: MyLibraryViewModel

    // MARK: - Private

    private let disposeBag = DisposeBag()

    // MARK: - Lifecycle

    init(_ navigationController: UINavigationController) {
        self.navigationController = navigationController
        let repository = LocalBookRepository()
        myLibraryViewModel = MyLibraryViewModel(bookRepository: repository)
        myLibraryViewController = MyLibraryViewController(viewModel: myLibraryViewModel)
    }

    // MARK: - Functions

    func start() { showMyLibraryScreen() }
}

extension MyLibraryCoordinator {
    /// 책 목록 화면 표시
    ///
    /// 책 목록 화면을 생성하고 ViewModel과 ViewController를 연결
    /// 사용자가 책을 선택하면 책 상세 화면으로 이동
    private func showMyLibraryScreen() {
        // 책 상세 화면으로 이동 이벤트 처리
        myLibraryViewModel.navigateToBookDetail
            .withUnretained(self)
            .subscribe(onNext: { coordinator, book in
                let bookDetailCoordinator = DefaultBookDetailCoordinator(
                    coordinator
                        .navigationController
                )

                coordinator.addChildCoordinator(bookDetailCoordinator)
                bookDetailCoordinator.finishDelegate = self
                bookDetailCoordinator.start(with: book)
            })
            .disposed(by: disposeBag)
        navigationController.pushViewController(myLibraryViewController, animated: true)
    }
}

extension MyLibraryCoordinator: CoordinatorFinishDelegate {
    func coordinatorDidFinish(childCoordinator: any Coordinator) {
        childCoordinators.removeAll { $0 === childCoordinator }
        navigationController.popViewController(animated: true)
    }
}
