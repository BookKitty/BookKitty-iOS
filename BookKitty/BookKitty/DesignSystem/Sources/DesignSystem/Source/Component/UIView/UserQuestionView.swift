//
//  UserQuestionView.swift
//  DesignSystem
//
//  Created by 임성수 on 2/4/25.
//

import SnapKit
import Then
import UIKit

public class UserQuestionView: UIScrollView {
    // MARK: - Properties

    // MARK: - Internal

    var questionText: String

    let contentView = UIView()
    let bodyLabel = BodyLabel()

    // MARK: - Lifecycle

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

    // MARK: - Functions

    // MARK: - Public

    public func setQuestionText(_ text: String) {
        bodyLabel.text = text
    }
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

@available(iOS 17.0, *)
#Preview {
    UserQuestionView(questionText: "text")
}
