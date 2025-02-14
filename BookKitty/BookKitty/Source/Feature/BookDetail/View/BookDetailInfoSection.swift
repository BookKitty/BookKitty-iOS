//
//  BookDetailInfoSection.swift
//  BookKitty
//
//  Created by 전성규 on 2/6/25.
//

import DesignSystem
import UIKit

final class BookDetailInfoSection: UIStackView {
    // MARK: - Properties

    // MARK: - Internal

    let inforView = BookDetailInfoView()

    // MARK: - Private

    private let titleLabel = TitleLabel(weight: .extraBold).then { $0.text = "책 정보" }

    // MARK: - Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)

        configureUI()
        configureHierarchy()
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Functions

    private func configureUI() {
        axis = .vertical
        spacing = Vars.spacing12
    }

    private func configureHierarchy() {
        [titleLabel, inforView].forEach { addArrangedSubview($0) }
    }
}
