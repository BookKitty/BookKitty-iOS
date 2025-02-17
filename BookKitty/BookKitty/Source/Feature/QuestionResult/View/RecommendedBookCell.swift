//
//  RecommendedBookCell.swift
//  BookKitty
//
//  Created by 권승용 on 2/5/25.
//

import DesignSystem
import SnapKit
import UIKit

/// 추천하는 책들을 나타내는 컬렉션뷰 셀
final class RecommendedBookCell: UICollectionViewCell {
    // MARK: - Static Properties

    // MARK: - Internal

    static let reuseIdentifier = "RecommendedBookCell"

    // MARK: - Properties

    // MARK: - Private

    private let recommendedBookView = RecommendedBookView(
        bookTitle: "",
        bookAuthor: "",
        imageLink: "",
        isOwned: false
    )

    // MARK: - Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureHierarchy()
        configureLayout()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Functions

    func configureCell(
        bookTitle: String,
        bookAuthor: String,
        imageUrl: String,
        isOwned: Bool
    ) {
        recommendedBookView.configureView(
            bookTitle: bookTitle,
            bookAuthor: bookAuthor,
            imageLink: imageUrl,
            isOwned: isOwned
        )
    }

    private func configureHierarchy() {
        addSubview(recommendedBookView)
    }

    private func configureLayout() {
        recommendedBookView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    RecommendedBookCell(frame: .zero)
}
