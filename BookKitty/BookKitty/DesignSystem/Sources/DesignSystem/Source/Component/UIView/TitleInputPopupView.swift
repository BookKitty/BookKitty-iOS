//
//  TitleInputPopupView.swift
//  DesignSystem
//
//  Created by 임성수 on 2/3/25.
//

import SnapKit
import Then
import UIKit

public class TitleInputPopupView: UIView {
    // MARK: - Properties

    // MARK: - Public

    public let cancelButton = RoundButton(title: "취소", isSecondary: true)
    public let confirmButton = RoundButton()

    public let buttonStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = Vars.spacing12
        $0.alignment = .center
        $0.distribution = .fillEqually
    }

    public let bookTitleInput = CustomInput()

    // MARK: - Private

    private let iconImageView = UIImageView().then {
        $0.preferredSymbolConfiguration = .init(pointSize: Vars.viewSizeSmall, weight: .regular)
        $0.backgroundColor = .clear
        $0.image = UIImage(systemName: "text.badge.plus")
        $0.tintColor = Colors.brandSub
    }

    private let messageLabel = BodyLabel(weight: .semiBold).then {
        $0.textAlignment = .center
        $0.text = "책 제목으로 직접 추가하기"
    }

    // MARK: - Lifecycle

    public init() {
        super.init(frame: .zero)

        setupViews()
        setupProperties()
        setupLayouts()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Setup UI

extension TitleInputPopupView {
    private func setupViews() {
        [
            iconImageView,
            messageLabel,
            bookTitleInput,
            buttonStackView,
        ].forEach { self.addSubview($0) }

        [
            cancelButton,
            confirmButton,
        ].forEach { buttonStackView.addArrangedSubview($0) }
    }

    private func setupProperties() {
        backgroundColor = Colors.background0
        layer.cornerRadius = Vars.radiusTiny
        setBiggerShadow(radius: Vars.radiusTiny)
    }

    private func setupLayouts() {
        iconImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().inset(Vars.spacing48)
        }

        messageLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Vars.paddingSmall)
            make.top.equalTo(iconImageView.snp.bottom).offset(Vars.spacing24)
        }

        bookTitleInput.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Vars.paddingSmall)
            make.top.equalTo(messageLabel.snp.bottom).offset(Vars.spacing24)
        }

        buttonStackView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Vars.paddingSmall)
            make.top.equalTo(bookTitleInput.snp.bottom).offset(Vars.spacing48)
            make.bottom.equalToSuperview().inset(Vars.paddingReg)
            make.height.equalTo(Vars.viewSizeReg)
        }
    }
}
