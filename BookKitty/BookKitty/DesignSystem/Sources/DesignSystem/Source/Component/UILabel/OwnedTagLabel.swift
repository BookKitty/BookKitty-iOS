//
//  OwnedTagLabel.swift
//  DesignSystem
//
//  Created by 임성수 on 2/3/25.
//

import SnapKit
import UIKit

public class OwnedTagLabel: UILabel {
    // MARK: - Properties

    // MARK: - Internal

    var isOwned: Bool

    // MARK: - Lifecycle

    public init(isOwned: Bool = true) {
        self.isOwned = isOwned
        super.init(frame: .zero)

        setupProperties()
        setupLayouts()
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Functions

    func configure(isOwned: Bool) {
        self.isOwned = isOwned
        setupProperties()
    }
}

// MARK: - UI Configure

extension OwnedTagLabel {
    private func setupProperties() {
        text = isOwned ? "소유" : "미소유"
        backgroundColor = isOwned ? Colors.brandSub : Colors.systemGray(.r100)
        textColor = Colors.fontWhite
        font = Fonts.captionSemiBold
        textAlignment = .center
        numberOfLines = 1
        layer.cornerRadius = Vars.radiusTiny
        clipsToBounds = true
    }

    private func setupLayouts() {
        snp.makeConstraints { make in
            make.height.equalTo(Vars.viewSizeTiny)
            make.width.equalTo(64)
        }
    }
}
