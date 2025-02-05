//
//  UserQuestionView.swift
//  DesignSystem
//
//  Created by MaxBook on 2/4/25.
//

import SnapKit
import Then
import UIKit

public class UserQuestionView: UIScrollView {
    // MARK: Lifecycle

    public init(questionText: String) {
        self.questionText = questionText
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

    var questionText: String

    let contentView = UIView()
    let bodyLabel = BodyLabel()
}

// MARK: - UI Configure

extension UserQuestionView {
    private func setupViews() {
        addSubview(contentView)
        contentView.addSubview(bodyLabel)
    }

    private func setupProperties() {
        backgroundColor = Colors.background1
        layer.cornerRadius = Vars.radiusTiny

        bodyLabel.text = questionText
    }

    private func setupLayouts() {
        snp.makeConstraints { make in
            make.height.equalTo(Vars.viewSizeHuge)
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }

        bodyLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(Vars.paddingReg)
        }
    }
}
