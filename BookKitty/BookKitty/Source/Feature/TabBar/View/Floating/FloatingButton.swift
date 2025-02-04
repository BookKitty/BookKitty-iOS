//
//  FloatingButton.swift
//  BookKitty
//
//  Created by 전성규 on 2/3/25.
//

import DesignSystem
import RxCocoa
import RxSwift
import SnapKit
import Then
import UIKit

final class FloatingButton: UIButton {
    // MARK: Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupUI()
        setupShadow()
        setupBindings()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    /// 버튼 회전 상태 여부를 나타내는 `BehaviorRelay`
    /// - `true`이면 버튼이 45도 회전하고, `false`이면 원래 상태로 복귀
    let isRotated = BehaviorRelay(value: false)

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: Vars.radiusTiny).cgPath
    }

    // MARK: Private

    private let disposeBag = DisposeBag()

    private func setupUI() {
        layer.cornerRadius = Vars.radiusReg
        setImage(UIImage(systemName: "plus"), for: .normal)
        tintColor = .white
        backgroundColor = Colors.brandSub
    }

    private func setupShadow() {
        layer.shadowColor = Colors.shadow15.cgColor
        layer.shadowRadius = 4.0
        layer.shadowOffset = CGSize(width: 0.0, height: 4.0)
        layer.shadowOpacity = 0.0
    }

    /// `isRotated` 값 변경을 감지하여 애니메이션을 적용하는 메서드
    private func setupBindings() {
        isRotated
            .distinctUntilChanged()
            .withUnretained(self)
            .bind { owner, isRotated in
                owner.animateRotation(isRotated)
                owner.animateShadow(isRotated)
            }.disposed(by: disposeBag)
    }
}

// MARK: Animate Method

extension FloatingButton {
    /// 버튼이 회전하는 애니메이션을 수행하는 메서드
    /// - `isRotated == true` → 45도 회전
    /// - `isRotated == false` → 원래 위치로 복귀
    private func animateRotation(_ isRotated: Bool) {
        UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseInOut) {
            self.transform = isRotated ? CGAffineTransform(rotationAngle: .pi / 4) : .identity
        }
    }

    /// 버튼 그림자의 투명도를 변경하는 애니메이션
    /// - `CABasicAnimation`을 사용하여 `shadowOpacity`를 부드럽게 변화시킴
    private func animateShadow(_ isRotated: Bool) {
        let animation = CABasicAnimation(keyPath: "shadowOpacity")
        animation.fromValue = layer.shadowOpacity
        animation.toValue = isRotated ? 1.0 : 0.0
        animation.duration = 0.3

        layer.add(animation, forKey: animation.keyPath)
        layer.shadowOpacity = isRotated ? 1.0 : 0.0
    }
}
