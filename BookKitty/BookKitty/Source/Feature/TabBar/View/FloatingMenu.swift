//
//  FloatingMenu.swift
//  BookKitty
//
//  Created by 전성규 on 1/31/25.
//

import SnapKit
import Then
import UIKit

/// 플로팅 메뉴 - 여러 메뉴 아이템을 담는 컨테이너 뷰
final class FloatingMenu: UIView {
    // MARK: Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)

        configureUI()
        configureHierarchy()
        configureLayout()
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    private(set) var items: [FloatingMenuItem] = FloatingMenuItemType.allCases.map {
        FloatingMenuItem(with: $0)
    }

    // MARK: Private

    /// 메뉴 아이템을 담을 `UIStackView`
    private let contentStackView = UIStackView().then {
        $0.axis = .vertical
        $0.distribution = .fillEqually
    }

    private func configureUI() {
        backgroundColor = .white
        layer.cornerRadius = 12.0
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
