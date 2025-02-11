//
//  ManageBookPopupView.swift
//  DesignSystem
//
//  Created by 임성수 on 2/3/25.
//

import SnapKit
import Then
import UIKit

public enum ManageBookMode {
    case add
    case delete
}

public class ManageBookPopupView: UIView {
    // MARK: - Properties

    // MARK: - Public

    public let bookTitle: String
    public let mode: ManageBookMode

    public let cancelButton = RoundButton(title: "취소", isSecondary: true)
    public let confirmButton = RoundButton()

    public let buttonStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = Vars.spacing12
        $0.alignment = .center
        $0.distribution = .fillEqually
    }

    // MARK: - Private

    private let iconImageView = UIImageView().then {
        $0.preferredSymbolConfiguration = .init(pointSize: Vars.viewSizeSmall, weight: .regular)
        $0.backgroundColor = .clear
    }

    private let messageLabel = BodyLabel().then {
        $0.textAlignment = .center
    }

    private let bookTitleLabel = BodyLabel(weight: .semiBold).then {
        $0.textAlignment = .center
        $0.textColor = Colors.brandSub
    }

    // MARK: - Lifecycle

    public init(bookTitle: String = "책 제목", mode: ManageBookMode) {
        self.bookTitle = bookTitle
        self.mode = mode
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

extension ManageBookPopupView {
    private func setupViews() {
        [
            iconImageView,
            messageLabel,
            bookTitleLabel,
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

        bookTitleLabel.text = bookTitle

        switch mode {
        case .add:
            messageLabel.text = "나의 책장에 아래의 책을 등록하시겠습니까?"
            iconImageView.image = UIImage(systemName: "trash.fill")
            iconImageView.tintColor = Colors.statusRed
        case .delete:
            messageLabel.text = "나의 책장에서 아래의 책을 제외하시겠습니까?"
            iconImageView.image = UIImage(systemName: "bookmark.fill")
            iconImageView.tintColor = Colors.brandMain
        }
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

        bookTitleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Vars.paddingSmall)
            make.top.equalTo(messageLabel.snp.bottom).offset(Vars.spacing12)
        }

        buttonStackView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Vars.paddingSmall)
            make.top.equalTo(bookTitleLabel.snp.bottom).offset(Vars.spacing48)
            make.bottom.equalToSuperview().inset(Vars.paddingReg)
            make.height.equalTo(Vars.viewSizeReg)
        }
    }
}
