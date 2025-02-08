//
//  DimmingView.swift
//  BookKitty
//
//  Created by 전성규 on 2/3/25.
//

import DesignSystem
import RxCocoa
import RxSwift
import UIKit

final class DimmingView: UIView {
    // MARK: - Properties

    // MARK: - Internal

    /// 현재 `DimmingView`의 가시성을 나타내는 `BehaviorRelay`
    /// - `true` → 배경이 보임 (`alpha = 1.0`)
    /// - `false` → 배경이 사라짐 (`alpha = 0.0`)
    let isVisible = BehaviorRelay(value: false)

    // MARK: - Private

    private let disposeBag = DisposeBag()

    // MARK: - Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)

        configureUI()
        setupTapGesture()
        bindVisibility()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Functions

    private func configureUI() {
        backgroundColor = Colors.backgroundModal
        alpha = 0.0
    }

    /// `isVisible` 값 변경을 감지하여 애니메이션 적용
    private func bindVisibility() {
        isVisible
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .bind { isVisible in
                UIView.animate(withDuration: 0.3) {
                    self.alpha = isVisible ? 1.0 : 0.0
                }
            }.disposed(by: disposeBag)
    }
}

extension DimmingView {
    /// 화면을 탭하면 `isVisible = false`로 변경하여 `DimmingView`를 숨김
    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer()
        addGestureRecognizer(tapGesture)

        tapGesture.rx.event
            .map { _ in false }
            .bind(to: isVisible)
            .disposed(by: disposeBag)
    }
}
