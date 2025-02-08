//
//  BookDetailIntroSection.swift
//  BookKitty
//
//  Created by 전성규 on 2/6/25.
//

import DesignSystem
import Then
import UIKit

final class BookDetailIntroSection: UIStackView {
    // MARK: - Lifecycle

    override init(frame _: CGRect) {
        super.init(frame: .zero)

        configureUI()
        configureHierarchy()
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Internal

    func setupData(with description: String) {
        introLabel.text = description
    }

    // MARK: - Private

    private let titleLabel = TitleLabel(weight: .extraBold).then { $0.text = "책 소개" }
    private let introLabel = BodyLabel(weight: .regular)

    private func configureUI() {
        axis = .vertical
        spacing = Vars.spacing12
    }

    private func configureHierarchy() {
        [titleLabel, introLabel].forEach { addArrangedSubview($0) }
    }
}
