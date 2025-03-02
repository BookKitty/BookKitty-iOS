//
//  MyLibraryCollectionViewCell.swift
//  BookKitty
//
//  Created by 권승용 on 2/6/25.
//

import DesignSystem
import NeoImage
import SnapKit
import UIKit

final class MyLibraryCollectionViewCell: UICollectionViewCell {
    // MARK: - Static Properties

    // MARK: - Internal

    static let reuseIdentifier = "MyLibraryCollectionViewCell"

    // MARK: - Properties

    // MARK: - Private

    private let cellImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.isUserInteractionEnabled = true
    }

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

    // TODO: 고도화 필요
    func configureCell(imageUrl: URL?) {
        cellImageView.neo.setImage(with: imageUrl)
    }

    private func configureHierarchy() {
        contentView.addSubview(cellImageView)
    }

    private func configureLayout() {
        cellImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
