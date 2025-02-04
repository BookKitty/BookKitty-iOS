//
//  FloatingMenu.swift
//  BookKitty
//
//  Created by 전성규 on 1/31/25.
//

import RxCocoa
import RxSwift
import SnapKit
import Then
import UIKit

/// 플로팅 메뉴 - 여러 메뉴 아이템을 담는 컨테이너 뷰
final class FloatingMenu: UIView {
    // MARK: Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupUI()
        configureHierarchy()
        configureLayout()
        bindVisibility()
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    private(set) var items: [FloatingMenuItem] = FloatingMenuItemType.allCases.map {
        FloatingMenuItem(with: $0)
    }

    /// 메뉴의 가시성 상태를 나타내는 `BehaviorRelay`
    /// - `true` → 메뉴가 보임 (`alpha = 1.0`)
    /// - `false` → 메뉴가 사라짐 (`alpha = 0.0`)
    let isVisible = BehaviorRelay(value: false)

    // MARK: Private

    private let disposeBag = DisposeBag()

    /// 메뉴 아이템을 담을 `UIStackView`
    private let contentStackView = UIStackView().then {
        $0.axis = .vertical
        $0.distribution = .fillEqually
    }

    private func setupUI() {
        backgroundColor = .white
        layer.cornerRadius = 12.0
        layer.shadowColor = UIColor.black.withAlphaComponent(0.15).cgColor
        layer.shadowOpacity = 1.0
        layer.shadowRadius = 4.0
        layer.shadowOffset = CGSize(width: 0.0, height: 4.0)

        alpha = 0.0
        transform = CGAffineTransform(translationX: 0.0, y: 20.0)
    }

    private func bindVisibility() {
        isVisible
            .distinctUntilChanged()
            .withUnretained(self)
            .bind { owner, isVisible in
                owner.animateMenuVisiblility(isVisible)
            }.disposed(by: disposeBag)
    }

    private func configureHierarchy() {
        addSubview(contentStackView)

        items.forEach { contentStackView.addArrangedSubview($0) }
    }

    private func configureLayout() {
        contentStackView.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview()
            $0.centerY.equalToSuperview()
        }

        for item in items {
            item.snp.makeConstraints { $0.height.equalTo(40.0) }
        }
    }
}

// MARK: Animate Method

extension FloatingMenu {
    private func animateMenuVisiblility(_ isVisible: Bool) {
        UIView.animate(
            withDuration: 0.3,
            delay: 0.0,
            usingSpringWithDamping: 0.7,
            initialSpringVelocity: 1.0,
            options: .curveEaseInOut
        ) {
            self.alpha = isVisible ? 1.0 : 0.0
            self.transform = isVisible ? .identity : CGAffineTransform(
                translationX: 0.0,
                y: 20.0
            )
        }
    }
}
