//
//  TabBarController.swift
//  BookKitty
//
//  Created by 전성규 on 1/29/25.
//

import RxCocoa
import RxSwift
import SnapKit
import UIKit

/// 커스텀 탭 바 컨트롤러
/// - `TabBarView`와 `viewControllers`를 관리하며, 선택된 탭에 따라 뷰 컨트롤러 전환
final class TabBarController: BaseViewController {
    // MARK: Lifecycle

    init(viewModel: TabBarViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    /// 관리할 뷰 컨트롤러 배열
    var viewControllers: [UIViewController] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        setupInitialViewController()
        bindTabBar()
    }

    override func configureHierarchy() {
        [tabBar].forEach { view.addSubview($0) }
    }

    override func configureLayout() {
        tabBar.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(24.0)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(4.0)
            $0.width.equalTo(286.0)
            $0.height.equalTo(48.0)
        }
    }

    // MARK: Private

    private let viewModel: TabBarViewModel
    private var currentIndex = 0
    private let tabBar = TabBarView()

    /// 탭 바에서 선택된 인덱스를 감지하고 뷰 컨트롤러 전환
    private func bindTabBar() {
        tabBar.selectedIndex
            .distinctUntilChanged()
            .withUnretained(self)
            .subscribe(onNext: { owner, index in
                owner.showViewController(at: index)
                owner.hideViewController(at: owner.currentIndex)
                owner.currentIndex = index
            }).disposed(by: disposeBag)
    }
}

// MARK: - 뷰 컨트롤러 관리

extension TabBarController {
    /// 탭 바에서 관리할 뷰 컨트롤러를 설정
    func setViewControllers(_ viewControllers: UIViewController...) {
        self.viewControllers.append(contentsOf: viewControllers)
    }

    /// 앱 시작 시 첫 번째 뷰 컨트롤러를 표시
    private func setupInitialViewController() { showViewController(at: 0) }

    /// 특정 인덱스의 뷰 컨트롤러를 표시
    private func showViewController(at index: Int) {
        guard index >= 0, index < viewControllers.count else {
            return
        }

        let viewController = viewControllers[index]
        addChild(viewController)
        view.addSubview(viewController.view)
        viewController.view.snp.makeConstraints { $0.edges.equalToSuperview() }
        viewController.didMove(toParent: self)
        view.bringSubviewToFront(tabBar)    // 탭 바를 항상 최상위에 유지
    }

    /// 특정 인덱스의 뷰 컨트롤러를 숨김
    private func hideViewController(at index: Int) {
        guard index >= 0, index < viewControllers.count else {
            return
        }

        let viewController = viewControllers[index]
        viewController.willMove(toParent: nil)
        viewController.view.snp.removeConstraints()
        viewController.view.removeFromSuperview()
        viewController.removeFromParent()
    }
}

@available(iOS 17.0, *)
#Preview {
    TabBarController(viewModel: TabBarViewModel())
}
