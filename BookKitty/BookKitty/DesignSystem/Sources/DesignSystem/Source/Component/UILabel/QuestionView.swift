//
//  QuestionLabel.swift
//  DesignSystem
//
//  Created by MaxBook on 2/4/25.
//

import SnapKit
import UIKit

public class QuestionView: UIScrollView {
    // MARK: Lifecycle

    public init(isOwned: Bool = true) {
        self.isOwned = isOwned
        super.init(frame: .zero)

        setupViews()
        setupProperties()
        setupLayouts()
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    var text: Bool
    
    let scrollView = UIScrollView()
    let contentView = UIView()
    
}

// MARK: - UI Configure

extension QuestionLabel {
    private func setupViews() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        [
            questionInput,
        ].forEach { contentView.addSubview($0) }
    }
    
    private func setupProperties() {
        view.backgroundColor = Colors.background0
    }

    private func setupLayouts() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
    }
}
