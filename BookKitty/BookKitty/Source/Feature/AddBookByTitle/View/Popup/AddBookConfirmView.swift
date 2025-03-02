//
//  AddBookConfirmView.swift
//  BookKitty
//
//  Created by 권승용 on 2/19/25.
//

import DesignSystem
import NeoImage
import RxSwift
import SnapKit
import Then
import UIKit

final class AddBookConfirmView: UIView {
    // MARK: - Properties

    let cancelButton = UIButton().then {
        $0.backgroundColor = Colors.brandSub2
        $0.setTitle("취소", for: .normal)
        $0.setTitleColor(Colors.fontWhite, for: .normal)
        $0.layer.cornerRadius = Vars.radiusMini
        $0.clipsToBounds = true
    }

    let confirmButton = UIButton().then {
        $0.backgroundColor = Colors.brandSub
        $0.setTitle("확인", for: .normal)
        $0.setTitleColor(Colors.fontWhite, for: .normal)
        $0.layer.cornerRadius = Vars.radiusMini
        $0.clipsToBounds = true
    }

    private let bookThumbnailImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
    }

    private let bookTitleLabel = UILabel().then {
        $0.font = Fonts.bodySemiBold
        $0.textColor = Colors.brandSub
        $0.numberOfLines = 2
        $0.textAlignment = .center
    }

    private let addDescriptionLabel = UILabel().then {
        $0.text = "위 책을 추가하시겠습니까?"
        $0.font = Fonts.bodyRegular
        $0.textColor = Colors.fontMain
        $0.textAlignment = .center
    }

    private lazy var buttonStackView = UIStackView(arrangedSubviews: [
        cancelButton,
        confirmButton,
    ]).then {
        $0.axis = .horizontal
        $0.distribution = .fillEqually
        $0.spacing = Vars.spacing8
        $0.alignment = .center
    }

    // MARK: - Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureBackground()
        configureHierarchy()
        configureLayout()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Functions

    func configure(thumbnailUrl: URL?, title: String) {
        bookTitleLabel.text = title
        bookThumbnailImageView.neo.setImage(with: thumbnailUrl)
    }

    private func configureBackground() {
        backgroundColor = Colors.background0
        layer.cornerRadius = Vars.radiusTiny
        clipsToBounds = true
    }

    private func configureHierarchy() {
        [
            bookThumbnailImageView,
            bookTitleLabel,
            addDescriptionLabel,
            buttonStackView,
        ].forEach { addSubview($0) }
    }

    private func configureLayout() {
        bookThumbnailImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Vars.spacing48)
            make.centerX.equalToSuperview()
            make.height.equalTo(Vars.imageFixedHeightSmall)
        }

        bookTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(bookThumbnailImageView.snp.bottom).offset(Vars.spacing20)
            make.centerX.equalToSuperview()
            make.horizontalEdges.equalToSuperview().inset(Vars.spacing20)
        }

        addDescriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(bookTitleLabel.snp.bottom).offset(Vars.spacing20)
            make.centerX.equalToSuperview()
            make.horizontalEdges.equalToSuperview().inset(Vars.spacing24)
        }

        buttonStackView.snp.makeConstraints { make in
            make.top.equalTo(addDescriptionLabel.snp.bottom).offset(Vars.spacing20)
            make.horizontalEdges.equalToSuperview().inset(Vars.spacing20)
            make.height.equalTo(Vars.viewSizeReg)
            make.bottom.equalToSuperview().offset(-Vars.spacing24)
        }

        cancelButton.snp.makeConstraints { make in
            make.height.equalTo(buttonStackView)
        }

        confirmButton.snp.makeConstraints { make in
            make.height.equalTo(buttonStackView)
        }
    }
}
