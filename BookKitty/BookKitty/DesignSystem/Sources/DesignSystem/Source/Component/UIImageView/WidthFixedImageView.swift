//
//  WidthFixedImageView.swift
//  DesignSystem
//
//  Created by MaxBook on 2/4/25.
//

import SnapKit
import UIKit

public enum BookImageFixedWidth {
    case regular
    case large
}

public class WidthFixedImageView: UIImageView, ImageLoadableView {
    // MARK: Lifecycle

    // MARK: - Initializer

    /// 너비가 고정된 이미지뷰.
    /// 책의 이미지를 표시하는데 사용.
    /// 두가지의 값(128, 144) 중 선택하여 사용합니다. ``BookImageFixedWidth`` 참고.
    ///
    /// - Parameters:
    ///   - imageUrl: 사용하고자 하는 이미지의
    public init(imageUrl: String = "", width: BookImageFixedWidth) {
        self.imageUrl = imageUrl
        fixedWidth = width
        super.init(frame: .zero)

        setupProperties()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Public

    public var imageUrl: String
    public var fixedWidth: BookImageFixedWidth
    public var onImageLoaded: (() -> Void)?
}

// MARK: - Setup UI

extension WidthFixedImageView {
    private func setupProperties() {
        contentMode = .scaleAspectFit
        clipsToBounds = true

        let imageWidth: CGFloat

        switch fixedWidth {
        case .regular:
            imageWidth = Vars.imageFixedWidth
        case .large:
            imageWidth = Vars.imageFixedWidthLarge
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
            
            self.image = bookImage

            // 이미지의 원본 비율에 맞춰 높이 조정
            if let imageSize = bookImage?.size {
                let aspectRatio = imageSize.height / imageSize.width
                self.snp.remakeConstraints { make in
                    make.width.equalTo(imageWidth) // 너비 고정
                    make.height.equalTo(imageWidth * aspectRatio) // 높이 자동 조정
                }
            }

            // 이미지 로딩 완료 후 콜백 실행
            self.onImageLoaded?()
        }
    }
}
