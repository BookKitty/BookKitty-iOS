//
//  RecommendedBookView.swift
//  DesignSystem
//
//  Created by MaxBook on 2/4/25.
//

import SnapKit
import Then
import UIKit

public class RecommendedBookView: UIView {
    // MARK: Lifecycle

    public init(
        bookTitle: String,
        bookAuthor: String,
        imageUrl: String,
        isOwened: Bool
    ) {
        tagLabel = OwnedTagLabel(isOwned: isOwened)
        bookImageView = HeightFixedImageView(imageUrl: imageUrl, height: .regular)
        bookTitleLabel = BodyLabel().then {
            $0.text = bookTitle
            $0.numberOfLines = 2
            $0.textAlignment = .center
        }
        bookAuthorLabel = CaptionLabel().then {
            $0.text = bookAuthor
            $0.textAlignment = .center
            $0.textColor = Colors.fontSub1
        }

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

    let tagLabel: OwnedTagLabel
    let bookImageView: HeightFixedImageView
    let bookTitleLabel: BodyLabel
    let bookAuthorLabel: CaptionLabel
}

// MARK: - UI Configure

extension RecommendedBookView {
    private func setupViews() {
        [
            tagLabel,
            bookImageView,
            bookTitleLabel,
            bookAuthorLabel,
        ].forEach { self.addSubview($0) }
    }

    private func setupProperties() {
        backgroundColor = Colors.background0
        layer.cornerRadius = Vars.radiusTiny
        setBasicShadow(radius: Vars.radiusTiny)
    }

    private func setupLayouts() {
        snp.makeConstraints { make in
            make.height.equalTo(Vars.viewSize320)
            make.width.equalTo(Vars.viewSize240)
        }

        tagLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(Vars.paddingReg)
            make.centerX.equalToSuperview()
        }

        bookImageView.snp.makeConstraints { make in
            make.top.equalTo(tagLabel.snp.bottom).offset(Vars.spacing20)
            make.centerX.equalToSuperview()
        }

        bookAuthorLabel.snp.makeConstraints { make in
            make.bottom.equalToSuperview().inset(Vars.paddingReg)
            make.leading.trailing.equalToSuperview().inset(Vars.paddingReg)
        }

        bookTitleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Vars.paddingReg)
            make.top.equalTo(tagLabel.snp.bottom).offset(Vars.spacing20 * 2 + Vars.imageFixedHeight)
            make.bottom.equalTo(bookAuthorLabel.snp.top).offset(Vars.spacing8)
        }
    }
}
