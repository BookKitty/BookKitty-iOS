//
//  AddBookByTitleCell.swift
//  BookKitty
//
//  Created by 권승용 on 2/17/25.
//

import DesignSystem
import SnapKit
import Then
import UIKit

final class AddBookByTitleCell: UICollectionViewCell {
    // MARK: - Properties

    private let imageView = HeightFixedImageView(height: .mini)

    private let bookTitleLabel = BodyLabel(weight: .regular)
    private let bookAuthorLabel = CaptionLabel(weight: .regular)
    private lazy var bookInfoStackView = UIStackView().then {
        $0.addArrangedSubview(bookTitleLabel)
        $0.addArrangedSubview(bookAuthorLabel)
        $0.axis = .vertical
        $0.alignment = .leading
        $0.spacing = Vars.spacing4
        $0.distribution = .equalSpacing
    }

    // MARK: - Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureHierarahy()
        configureLayout()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Functions

    func configureCell(imageLink: String, bookTitle: String, author: String) {
        imageView.setupImage(imageLink: imageLink)
        bookTitleLabel.text = bookTitle
        bookAuthorLabel.text = author
    }

    private func configureHierarahy() {
        [
            imageView,
            bookInfoStackView,
        ].forEach { contentView.addSubview($0) }
    }

    private func configureLayout() {
        imageView.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.verticalEdges.equalToSuperview()
        }

        bookInfoStackView.snp.makeConstraints { make in
            make.leading.equalTo(imageView.snp.trailing).offset(Vars.spacing8)
            make.centerY.equalToSuperview()
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    let cell = AddBookByTitleCell(frame: .zero)
    cell.configureCell(imageLink: "", bookTitle: "책 제목", author: "책 저자")
    return cell
}
