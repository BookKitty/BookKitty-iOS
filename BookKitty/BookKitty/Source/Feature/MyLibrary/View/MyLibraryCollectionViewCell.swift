//
//  MyLibraryCollectionViewCell.swift
//  BookKitty
//
//  Created by 권승용 on 2/6/25.
//

import DesignSystem
import SnapKit
import UIKit

final class MyLibraryCollectionViewCell: UICollectionViewCell {
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

    // MARK: - Internal

    static let reuseIdentifier = "MyLibraryCollectionViewCell"

    override func prepareForReuse() {
        super.prepareForReuse()
        // 기존 요청 취소 및 기본 이미지 설정
        imageLoadTask?.cancel()
        cellImageView.image = nil
        currentImageUrl = nil
    }

    // TODO: 고도화 필요
    func configureCell(imageUrl: URL?) {
        // 기존 요청이 있다면 취소
        imageLoadTask?.cancel()
        currentImageUrl = imageUrl

        guard let imageUrl else {
            cellImageView.image = UIImage(systemName: "photo")
            return
        }

        let request = URLRequest(
            url: imageUrl,
            cachePolicy: .returnCacheDataElseLoad,
            timeoutInterval: 10
        )
        imageLoadTask = URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let self, let data, error == nil, let image = UIImage(data: data) else {
                DispatchQueue.main.async {
                    if self?.currentImageUrl == imageUrl {
                        self?.cellImageView.image = UIImage(systemName: "photo")
                    }
                }
                return
            }

            DispatchQueue.main.async {
                if self.currentImageUrl == imageUrl {
                    self.cellImageView.image = image
                }
            }
        }
        imageLoadTask?.resume()
    }

    // MARK: - Private

    private var imageLoadTask: URLSessionDataTask?
    private var currentImageUrl: URL?

    private let cellImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.isUserInteractionEnabled = true
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
