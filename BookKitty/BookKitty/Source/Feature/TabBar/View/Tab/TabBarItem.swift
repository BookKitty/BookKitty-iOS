//
//  TabBarItem.swift
//  BookKitty
//
//  Created by 전성규 on 1/30/25.
//

import DesignSystem
import RxSwift
import UIKit

/// 커스텀 탭 바 버튼
/// - `TabBarItemType`을 기반으로 UI를 설정하고, 탭 이벤트를 Rx로 제공
final class TabBarItem: UIButton {
    // MARK: - Lifecycle

    init(with type: TabBarItemType) {
        self.type = type
        super.init(frame: .zero)

        setupButtonConfiguration()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Internal

    let type: TabBarItemType

    // MARK: - Private

    private func setupButtonConfiguration() {
        var configuration = UIButton.Configuration.plain()
        var attributedTitle = AttributedString(type.rawValue)
        attributedTitle.font = Fonts.captionRegular

        configuration.attributedTitle = attributedTitle
        configuration.baseForegroundColor = .black
        configuration.image = UIImage(systemName: type.iconName)
        configuration.imagePlacement = .top
        configuration.imagePadding = Vars.spacing4
        configuration.preferredSymbolConfigurationForImage = UIImage
            .SymbolConfiguration(pointSize: 12.0)

        self.configuration = configuration
        layer.cornerRadius = Vars.radiusReg
    }
}

// MARK: - RxSwift 확장

extension Reactive where Base: TabBarItem {
    /// 버튼이 탭될 때 해당 `TabBarItemType`의 `index`를 방출
    var selectedTabIndex: Observable<Int> {
        base.rx.tap
            .withUnretained(base)
            .map { tabBarItem, _ in tabBarItem.type.index }
    }
}
