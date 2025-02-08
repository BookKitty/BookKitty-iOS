//
//  RecommendedBookView.swift
//  DesignSystem
//
//  Created by 임성수 on 2/4/25.
//

import SnapKit
import Then
import UIKit

public class RecommendedBookView: UIView {
    // MARK: - Lifecycle

    public init(
        bookTitle: String,
        bookAuthor: String,
        imageUrl: String,
        isOwned: Bool
    ) {
        tagLabel = OwnedTagLabel(isOwned: isOwned)
        bookImageView = HeightFixedImageView(imageUrl: imageUrl, height: .regular)
        bookTitleLabel = BodyLabel(weight: .semiBold).then {
            $0.text = bookTitle
            $0.numberOfLines = 2
            $0.textAlignment = .center
            $0.textColor = Colors.fontMain
        }
        bookAuthorLabel = CaptionLabel().then {
            $0.text = bookAuthor
            $0.numberOfLines = 1
            $0.textAlignment = .center
            $0.textColor = Colors.fontSub2
        }

        super.init(frame: .zero)

        setupViews()
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func layoutSubviews() {
        super.layoutSubviews()

        setupLayouts()
        setupProperties()
    }

    // MARK: - Public

    public func configureView(
        bookTitle: String,
        bookAuthor: String,
        imageUrl: String,
        isOwned: Bool
    ) {
        tagLabel.configure(isOwned: isOwned)
        bookImageView.configure(imageUrl: imageUrl)
        bookTitleLabel.text = bookTitle
        bookAuthorLabel.text = bookAuthor
    }

    // MARK: - Internal

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

        bookImageView.setBookShadow()
    }

    private func setupLayouts() {
        snp.makeConstraints { make in
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

        bookTitleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Vars.paddingReg)
            make.top.equalTo(bookImageView.snp.bottom).offset(Vars.spacing32)
            make.height.equalTo(Vars.viewSizeMedium)
        }

        bookAuthorLabel.snp.makeConstraints { make in
            make.top.equalTo(bookTitleLabel.snp.bottom).offset(Vars.spacing12)
            make.leading.trailing.equalToSuperview().inset(Vars.paddingReg)
            make.height.equalTo(Vars.viewSizeMini)
            make.bottom.equalToSuperview().inset(Vars.paddingReg)
        }
    }
}
