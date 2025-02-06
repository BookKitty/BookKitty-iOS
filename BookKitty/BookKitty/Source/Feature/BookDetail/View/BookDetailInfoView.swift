//
//  BookDetailInfoView.swift
//  BookKitty
//
//  Created by 전성규 on 2/6/25.
//

import DesignSystem
import SnapKit
import Then
import UIKit

final class BookDetailInfoView: UIStackView {
    // MARK: Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)

        configureUI()
        configureHierarchy()
        configureLayout()
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    override func layoutSubviews() {
        super.layoutSubviews()
        configureLayout()
    }

    func setupData(with model: TestBookModel) {
        bookThumbnailImageView.setupImage(imageLink: model.imageLink)
        titleLabel.text = model.title
        authorLabel.text = model.author
        pubDateLabel.text = model.pubdate
        isbnLabel.text = "ISBN: \(model.isbn)"
        priceLabel.text = "가격 \(model.price)"
    }

    // MARK: Private

    private let topSpacingView = UIView()

    private let bookInfoHStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.alignment = .center
    }

    private let leadingSpacingView = UIView()
    private var bookThumbnailImageView = WidthFixedImageView(width: .regular)
    private let centerSpacingView = UIView()
    private let bookDetailInfoVStackView = UIStackView().then {
        $0.axis = .vertical
        $0.alignment = .leading
        $0.spacing = Vars.spacing20
    }

    private let titleLabel = BodyLabel(weight: .semiBold).then {
        $0.numberOfLines = 0
    }

    private let detailTextVStackView = UIStackView().then {
        $0.axis = .vertical
        $0.alignment = .leading
        $0.distribution = .equalSpacing
        $0.spacing = Vars.spacing4
    }

    private let authorLabel = CaptionLabel(weight: .regular).then {
        $0.numberOfLines = 0
    }

    private let pubDateLabel = CaptionLabel(weight: .regular).then {
        $0.text = "2025년 1월 20일 출판"
    }

    private let isbnLabel = CaptionLabel(weight: .regular)
    private let priceLabel = CaptionLabel(weight: .semiBold)

    private let trailingSpacingView = UIView()
    private let bottomSpacingView = UIView()

    private func configureUI() {
        axis = .vertical
        backgroundColor = Colors.background1
        layer.cornerRadius = Vars.radiusMini
        clipsToBounds = true
    }

    private func configureHierarchy() {
        [topSpacingView, bookInfoHStackView, bottomSpacingView].forEach { addArrangedSubview($0) }

        [
            leadingSpacingView,
            bookThumbnailImageView,
            centerSpacingView,
            bookDetailInfoVStackView,
            trailingSpacingView,
        ].forEach { bookInfoHStackView.addArrangedSubview($0) }

        [titleLabel, detailTextVStackView, priceLabel]
            .forEach { bookDetailInfoVStackView.addArrangedSubview($0) }

        [authorLabel, pubDateLabel, isbnLabel]
            .forEach { detailTextVStackView.addArrangedSubview($0) }
    }

    private func configureLayout() {
        topSpacingView.snp.makeConstraints { $0.height.equalTo(Vars.spacing24) }
        leadingSpacingView.snp.makeConstraints { $0.width.equalTo(Vars.spacing16) }
        centerSpacingView.snp.makeConstraints { $0.width.equalTo(Vars.spacing24) }
        trailingSpacingView.snp.makeConstraints { $0.width.equalTo(Vars.spacing16) }
        bottomSpacingView.snp.makeConstraints { $0.height.equalTo(Vars.spacing24) }
    }

    private func createWidthFixedImageView(for imageLink: String) -> WidthFixedImageView {
        WidthFixedImageView(imageUrl: imageLink, width: .regular)
    }
}

@available(iOS 17.0, *)
#Preview {
    let containerView = UIView().then { $0.backgroundColor = .white }
    let bookDetailInfoView = BookDetailInfoView()

    containerView.addSubview(bookDetailInfoView)
    bookDetailInfoView.snp.makeConstraints {
        $0.top.equalToSuperview().inset(100)
        $0.horizontalEdges.equalToSuperview().inset(Vars.paddingReg)
    }

    return containerView
}
