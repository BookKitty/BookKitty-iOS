//
//  FailAlertPopupView.swift
//  DesignSystem
//
//  Created by 임성수 on 2/3/25.
//

import SnapKit
import Then
import UIKit

public class FailAlertPopupView: UIView {
    // MARK: Lifecycle

    public init(
        primaryMessage: String = "촬영에 실패하였습니다.",
        secondaryMessage: String = "지속적으로 실패할 경우 한권씩 책 등처럼 제목을 쉽게 식별가능한 사진을 찍어주세요.",
        buttonTitle: String = "다시 촬영하기"
    ) {
        self.primaryMessage = primaryMessage
        self.secondaryMessage = secondaryMessage
        self.buttonTitle = buttonTitle
        super.init(frame: .zero)

        setupViews()
        setupProperties()
        setupLayouts()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Public

    public let primaryMessage: String
    public let secondaryMessage: String
    public let buttonTitle: String

    public let confirmButton = RoundButton()

    // MARK: Private

    private let iconImageView = UIImageView().then {
        $0.image = UIImage(systemName: "exclamationmark.triangle.fill")
        $0.tintColor = Colors.statusRed
        $0.preferredSymbolConfiguration = .init(pointSize: Vars.viewSizeSmall, weight: .regular)
        $0.backgroundColor = .clear
    }

    private let primaryMessageLabel = BodyLabel().then {
        $0.textAlignment = .center
        $0.textColor = Colors.statusRed
    }

    private let secondaryMessageLabel = BodyLabel().then {
        $0.textAlignment = .center
    }
}

// MARK: - Setup UI

extension FailAlertPopupView {
    private func setupViews() {
        [
            iconImageView,
            primaryMessageLabel,
            secondaryMessageLabel,
            confirmButton,
        ].forEach { self.addSubview($0) }
    }

    private func setupProperties() {
        backgroundColor = Colors.background0
        layer.cornerRadius = Vars.radiusTiny
        setBiggerShadow(radius: Vars.radiusTiny)

        primaryMessageLabel.text = primaryMessage
        secondaryMessageLabel.text = secondaryMessage
        confirmButton.setButtonTitle(buttonTitle)
    }

    private func setupLayouts() {
        iconImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().inset(Vars.spacing48)
        }

        primaryMessageLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Vars.paddingSmall)
            make.top.equalTo(iconImageView.snp.bottom).offset(Vars.spacing20)
        }

        secondaryMessageLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Vars.paddingSmall)
            make.top.equalTo(primaryMessageLabel.snp.bottom).offset(Vars.spacing20)
        }

        confirmButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Vars.paddingSmall)
            make.top.equalTo(secondaryMessageLabel.snp.bottom).offset(Vars.spacing48)
            make.bottom.equalToSuperview().inset(Vars.paddingReg)
        }
    }
}
