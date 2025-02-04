//
//  HeightFixedImageView.swift
//  DesignSystem
//
//  Created by MaxBook on 2/4/25.
//

import SnapKit
import UIKit

public enum BookImageFixedHeight {
    case regular
    case small
}

@MainActor
public class HeightFixedImageView: UIImageView, ImageLoadableView {
    // MARK: Lifecycle

    // MARK: - Initializer

    /// 높이가 고정된 이미지뷰.
    /// 책 이미지를 표시하는데 사용되며, 높이값은 200 고정입니다.
    ///
    /// - Parameters:
    ///   - imageUrl: 사용하고자 하는 이미지의
    public init(imageUrl: String = "", height: BookImageFixedHeight) {
        self.imageUrl = imageUrl
        fixedHeight = height
        super.init(frame: .zero)

        setupProperties()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Public

    public var imageUrl: String
    public var fixedHeight: BookImageFixedHeight
    public var onImageLoaded: (() -> Void)?
}

// MARK: - Setup UI

extension HeightFixedImageView {
    @MainActor
    private func setupProperties() {
        contentMode = .scaleAspectFit
        clipsToBounds = true

        let imageHeight: CGFloat

        switch fixedHeight {
        case .regular:
            imageHeight = Vars.imageFixedHeight
        case .small:
            imageHeight = Vars.imageFixedHeightSmall
        }

        imageUrl.loadAsyncImage { [weak self] image in
            guard let self else {
                return
            }
            
            let bookImage = image ?? UIImage(
                named: "DefaultBookImage",
                in: Bundle.module,
                compatibleWith: nil
            )
            
            DispatchQueue.main.async {
                self.image = bookImage
            
                // 이미지의 원본 비율에 맞춰 높이 조정
                if let imageSize = bookImage?.size {
                    let aspectRatio = imageSize.width / imageSize.height
                    self.snp.remakeConstraints { make in
                        make.height.equalTo(imageHeight) // 높이 고정
                        make.width.equalTo(imageHeight * aspectRatio) // 너비 자동 조정
                    }
                }
                // 이미지 로딩 완료 후 콜백 실행
                self.onImageLoaded?()
            }
        }
    }
}
