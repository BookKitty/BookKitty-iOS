//
//  TabBarView.swift
//  BookKitty
//
//  Created by 전성규 on 1/29/25.
//

import DesignSystem
import RxCocoa
import RxSwift
import Then
import UIKit

/// 커스텀 탭 바 뷰
/// - `TabBarItem`을 **수평**으로 배치하고, 선택된 인덱스를 Rx로 전달
final class TabBarView: UIStackView {
    // MARK: - Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)

        configureUI()
        configureHierarchy()
        bindSelectedIndex()
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Internal

    /// 선택된 탭의 인덱스를 방출하는 Relay
    let selectedIndex = BehaviorRelay(value: 0)

    // MARK: - Private

    private let disposeBag = DisposeBag()

    private let indicator = UIView().then {
        $0.backgroundColor = Colors.brandMain
        $0.layer.cornerRadius = Vars.radiusReg
    }

    private func bindSelectedIndex() {
        selectedIndex
            .asDriver(onErrorJustReturn: 0)
            .drive(onNext: { [weak self] index in
                self?.updateIndicator(index: index)
            }).disposed(by: disposeBag)
    }

    private func updateIndicator(index: Int) {
        guard index < arrangedSubviews.count else {
            return
        }

        let targetView = arrangedSubviews[index]
        let newCenter = targetView.center
        let newBounds = targetView.bounds

        UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseIn, animations: {
            self.indicator.transform = CGAffineTransform(scaleX: 0.83, y: 0.83)
            self.indicator.alpha = 0.7
        }, completion: { _ in
            UIView.animate(
                withDuration: 0.45,
                delay: 0.0,
                usingSpringWithDamping: 0.45,
                initialSpringVelocity: 0.7,
                options: .curveEaseOut,
                animations: {
                    self.indicator.center = newCenter
                    self.indicator.bounds = newBounds
                    self.indicator.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
                },
                completion: { _ in
                    UIView.animate(
                        withDuration: 0.2,
                        delay: 0.0,
                        options: .curveEaseInOut,
                        animations: {
                            self.indicator.transform = .identity
                        }
                    )
                }
            )
        })
    }

    /// `TabBarItem`을 생성하고 `selectedIndex`와 바인딩
    private func configureHierarchy() {
        for type in TabBarItemType.allCases {
            let item = TabBarItem(with: type)
                .then {
                    $0.rx.selectedTabIndex
                        .bind(to: selectedIndex)
                        .disposed(by: disposeBag)
                }

            addArrangedSubview(item)
        }

        insertSubview(indicator, at: 0)

        DispatchQueue.main.async {
            self.updateIndicator(index: 0)
        }
    }

    private func configureUI() {
        axis = .horizontal
        distribution = .fillEqually
        layer.cornerRadius = Vars.radiusReg
        backgroundColor = Colors.background2
    }
}
