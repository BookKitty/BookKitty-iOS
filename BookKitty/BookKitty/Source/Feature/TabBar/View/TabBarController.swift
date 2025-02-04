//
//  TabBarController.swift
//  BookKitty
//
//  Created by 전성규 on 1/29/25.
//

import DesignSystem
import RxCocoa
import RxSwift
import SnapKit
import Then
import UIKit

/// 커스텀 탭 바 컨트롤러
/// - `TabBarView`와 `viewControllers`를 관리하며, 선택된 탭에 따라 뷰 컨트롤러 전환
/// - 플로팅 메뉴(`FloatingMenu`)와 플로팅 버튼(`FloatingButton`)의 상태를 관리.
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
        bindFloatingMenuInteractions()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.navigationBar.isHidden = true
    }

    override func bind() {
        let selectedFloatingItem = PublishRelay<FloatingMenuItemType>()

        // 플로팅 메뉴 아이템의 선택 이벤트를 Rx로 바인딩
        for item in floatingMenu.items {
            item.rx.selectedItem
                .bind(to: selectedFloatingItem)
                .disposed(by: disposeBag)
        }

        let input = TabBarViewModel.Input(
            selectedFloatingItem: selectedFloatingItem.asObservable()
        )

        _ = viewModel.transform(input)
    }

    override func configureHierarchy() {
        [tabBar, dimmingView, floatingButton, floatingMenu].forEach { view.addSubview($0) }
    }

    override func configureLayout() {
        tabBar.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(Vars.paddingReg)
            $0.trailing.equalTo(floatingButton.snp.leading).offset(-Vars.spacing20)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(Vars.spacing4)
            $0.height.equalTo(Vars.viewSizeReg)
        }

        dimmingView.snp.makeConstraints { $0.edges.equalToSuperview() }

        floatingButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(Vars.paddingReg)
            $0.bottom.equalTo(tabBar.snp.bottom)
            $0.width.height.equalTo(Vars.viewSizeReg)
        }

        floatingMenu.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(Vars.paddingReg)
            $0.bottom.equalTo(floatingButton.snp.top).offset(-Vars.spacing20)
            $0.width.equalTo(196.0)
            $0.height.equalTo(104.0)
        }
    }

    // MARK: Private

    private let viewModel: TabBarViewModel

    /// 현재 선택된 탭의 인덱스
    private var currentIndex = 0

    ///    /// 플로팅 메뉴의 표시 여부를 관리하는 BehaviorRelay
    ///    private let isHiddenFloating = BehaviorRelay(value: true)
    private let isFloatingActive = BehaviorRelay(value: false)

    private let tabBar = TabBarView()
    private let dimmingView = DimmingView()
    private let floatingButton = FloatingButton()
    private let floatingMenu = FloatingMenu()

    // MARK: - Rx Binding

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

    /// 플로팅 버튼과 메뉴의 상태를 Rx로 바인딩하는 메서드
    private func bindFloatingMenuInteractions() {
        // 플로팅 버튼 탭 이벤트 처리
        floatingButton.rx.tap
            .withUnretained(self)
            .observe(on: MainScheduler.asyncInstance)
            .bind { owner, _ in
                let newState = !owner.isFloatingActive.value
                owner.isFloatingActive.accept(newState)
            }.disposed(by: disposeBag)

        // 플로팅 메뉴, 버튼, dimmingView 상태 연동
        isFloatingActive
            .distinctUntilChanged()
            .withUnretained(self)
            .observe(on: MainScheduler.asyncInstance)
            .bind { owner, isActive in
                owner.floatingButton.isRotated.accept(isActive)
                owner.floatingMenu.isVisible.accept(isActive)
                owner.dimmingView.isVisible.accept(isActive)
            }.disposed(by: disposeBag)

        // dimmingView를 탭하면 플로팅 메뉴 닫기
        dimmingView.isVisible
            .filter { !$0 }
            .withUnretained(self)
            .observe(on: MainScheduler.asyncInstance)
            .bind { owner, _ in
                owner.isFloatingActive.accept(false)
            }.disposed(by: disposeBag)
    }
}

// MARK: - 뷰 컨트롤러 관리

extension TabBarController {
    /// 탭 바에서 관리할 뷰 컨트롤러를 설정
    func setViewControllers(_ viewControllers: UIViewController...) {
        self.viewControllers = viewControllers
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
        [tabBar, dimmingView, floatingButton, floatingMenu]
            .forEach { view.bringSubviewToFront($0) }
    }

    /// 특정 인덱스의 뷰 컨트롤러를 숨김
    private func hideViewController(at index: Int) {
        guard index >= 0, index < viewControllers.count else {
            return
        }

        let viewController = viewControllers[index]
        viewController.willMove(toParent: nil)
        viewController.view.removeFromSuperview()
        viewController.removeFromParent()
    }
}

@available(iOS 17.0, *)
#Preview {
    TabBarController(viewModel: TabBarViewModel())
}
