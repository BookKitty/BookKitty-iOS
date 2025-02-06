//
//  HeightFixedImageView.swift
//  DesignSystem
//
//  Created by 임성수 on 2/4/25.
//

import SnapKit
import UIKit

public enum BookImageFixedHeight {
    case regular
    case small
    case mini
}

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

        switch height {
        case .regular:
            fixedHeight = Vars.imageFixedHeight
        case .small:
            fixedHeight = Vars.imageFixedHeightSmall
        case .mini:
            fixedHeight = Vars.imageFixedHeightMini
        }
        super.init(frame: .zero)

        setupProperties()
        setupLayouts()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Public

    public var imageUrl: String
    public var fixedHeight: CGFloat
    public var isRounded = false
    public var onImageLoaded: (() -> Void)?
}

// MARK: - Setup UI

extension HeightFixedImageView {
    private func setupProperties() {
        contentMode = .scaleAspectFit
        clipsToBounds = true

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
                let aspectRatio = imageSize.width / imageSize.height
                snp.remakeConstraints { make in
                    make.height.equalTo(fixedHeight) // 높이 고정
                    make.width.equalTo(fixedHeight * aspectRatio) // 너비 자동 조정
                }
            }
            // 이미지 로딩 완료 후 콜백 실행
            onImageLoaded?()
        }
    }

    private func setupLayouts() {
        snp.makeConstraints { make in
            make.height.equalTo(fixedHeight)
            make.width.greaterThanOrEqualTo(Vars.viewSizeReg)
        }
    }
}

// MARK: - Methods

extension HeightFixedImageView {
    public func toggleRadius() {
        isRounded = !isRounded
        layer.cornerRadius = isRounded ? Vars.radiusMini : 0
    }
}
