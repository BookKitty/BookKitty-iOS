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
    // MARK: - Properties

    // MARK: - Internal

    /// 선택된 탭의 인덱스를 방출하는 Relay
    let selectedIndex = BehaviorRelay(value: 0)

    // MARK: - Private

    private let disposeBag = DisposeBag()
    private let indicator = UIView().then {
        $0.backgroundColor = Colors.brandMain
        $0.layer.cornerRadius = Vars.radiusReg
    }

    // MARK: - Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)

        configureUI()
        configureHierarchy()
        bindSelectedIndex()
        setupInitialIndicator()
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Functions

    private func bindSelectedIndex() {
        selectedIndex
            .skip(1) // 처음 실행 시 애니메이션 방지
            .asDriver(onErrorJustReturn: 0)
            .drive(onNext: { [weak self] index in
                self?.updateIndicator(index: index, animate: true)
            }).disposed(by: disposeBag)
    }

    private func updateIndicator(index: Int, animate: Bool = true) {
        guard index < arrangedSubviews.count else {
            return
        }

        let targetView = arrangedSubviews[index]
        let newCenter = targetView.center
        let newBounds = targetView.bounds

        if animate {
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
        } else {
            indicator.center = newCenter
            indicator.bounds = newBounds
        }
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
    }

    /// 처음 실행 시 애니메이션 없이 indicator 위치 설정
    private func setupInitialIndicator() {
        if let firstItem = arrangedSubviews.first {
            indicator.frame = firstItem.frame
            indicator.center = firstItem.center
        }

        DispatchQueue.main.async {
            self.updateIndicator(index: 0, animate: false)
        }
    }

    private func configureUI() {
        axis = .horizontal
        distribution = .fillEqually
        layer.cornerRadius = Vars.radiusReg
        backgroundColor = Colors.background2
    }
}
