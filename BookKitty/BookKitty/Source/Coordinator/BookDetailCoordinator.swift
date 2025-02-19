//
//  BookDetailCoordinator.swift
//  BookKitty
//
//  Created by 전성규 on 2/17/25.
//

import RxRelay
import RxSwift
import UIKit

protocol BookDetailCoordinator: Coordinator {
    func start(with dookDetail: Book)
}

final class DefaultBookDetailCoordinator: BookDetailCoordinator {
    // MARK: - Properties

    var finishDelegate: CoordinatorFinishDelegate?

    var childCoordinators: [Coordinator] = []

    var navigationController: UINavigationController

    private let disposeBag = DisposeBag()

    // MARK: - Lifecycle

    init(_ navigaitonController: UINavigationController) {
        navigationController = navigaitonController
    }

    // MARK: - Functions

    func start() {}

    func start(with bookDetail: Book) {
        let repository = LocalBookRepository()
        let viewModel = BookDetailViewModel(bookDetail: bookDetail, bookRepository: repository)
        let viewController = BookDetailViewController(viewModel: viewModel)

        navigationController.pushViewController(viewController, animated: true)

        viewModel.navigateBackRelay
            .observe(on: MainScheduler.instance)
            .withUnretained(self)
            .bind(onNext: { owner, _ in
                owner.finish()
            }).disposed(by: disposeBag)
    }
}
