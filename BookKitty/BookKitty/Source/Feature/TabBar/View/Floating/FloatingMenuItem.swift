//
//  FloatingMenuItem.swift
//  BookKitty
//
//  Created by 전성규 on 1/31/25.
//

import DesignSystem
import RxSwift
import Then
import UIKit

final class FloatingMenuItem: UIButton {
    // MARK: - Lifecycle

    init(with type: FloatingMenuItemType) {
        self.type = type
        super.init(frame: .zero)

        configureHierarchy()
        configureLayout()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Internal

    let type: FloatingMenuItemType

    // MARK: - Private

    private let contentHStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.alignment = .center
        $0.distribution = .equalSpacing
        $0.spacing = Vars.spacing8
        $0.isUserInteractionEnabled = false
    }

    private lazy var contentImageView = UIImageView().then {
        $0.image = UIImage(systemName: type.iconName)
        $0.tintColor = type.iconColor
        $0.contentMode = .scaleAspectFit
    }

    private lazy var contentLabel = UILabel().then {
        $0.text = type.rawValue
        $0.textColor = Colors.fontMain
        $0.font = Fonts.bodyRegular
    }

    private func configureHierarchy() {
        addSubview(contentHStackView)

        [contentImageView, contentLabel].forEach { contentHStackView.addArrangedSubview($0) }
    }

    private func configureLayout() {
        contentHStackView.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(Vars.spacing20)
            $0.centerY.equalToSuperview()
        }

        contentImageView.snp.makeConstraints { $0.width.height.equalTo(Vars.viewSizeTiny) }
    }
}

extension Reactive where Base: FloatingMenuItem {
    var selectedItem: Observable<FloatingMenuItemType> {
        base.rx.tap
            .map { base.type }
    }
}
