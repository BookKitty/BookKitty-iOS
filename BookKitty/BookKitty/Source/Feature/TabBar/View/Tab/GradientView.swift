//
//  GradientView.swift
//  BookKitty
//
//  Created by 전성규 on 2/4/25.
//

import DesignSystem
import UIKit

/// **GradientView**
/// `CAGradientLayer`를 사용하여 그라데이션 배경을 적용하는 커스텀 뷰
///
/// - `startPoint`, `endPoint`, `colors`를 설정하여 수직 방향의 그라데이션을 적용
/// - `layoutSubviews()`에서 크기 변경 시 그라데이션을 다시 설정하여 반응형 레이아웃 대응
final class GradientView: UIView {
    // MARK: Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGradient()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    /// CALayer대신 CAGradientLayer를 기본 레이어로 사용하도록 설정
    override static var layerClass: AnyClass {
        CAGradientLayer.self
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        setupGradient()
    }

    // MARK: Private

    /// `CAGradientLayer`를 설정하는 메서드
    /// - 그라데이션 색상 및 방향을 지정
    private func setupGradient() {
        guard let gradientLayer = layer as? CAGradientLayer else {
            return
        }

        // 위쪽으로 흐려지는 효과 적용
        gradientLayer.colors = [
            Colors.fontWhite.cgColor,
            Colors.fontWhite.withAlphaComponent(0.0).cgColor,
        ]

        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.22)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 0.0)
    }
}
