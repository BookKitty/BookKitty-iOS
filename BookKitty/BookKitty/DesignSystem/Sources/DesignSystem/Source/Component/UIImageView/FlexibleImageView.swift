//
//  FlexibleImageView.swift
//  DesignSystem
//
//  Created by 임성수 on 2/4/25.
//

import SnapKit
import UIKit

public class FlexibleImageView: UIImageView {
    // MARK: - Properties

    // MARK: - Public

    public var imageLink: String
    public var viewWidth: CGFloat

    // MARK: - Lifecycle

    // MARK: - Initializer

    /// 가로값 기준 세로값이 정해지는 이미지뷰.
    /// 책의 이미지를 표시하는데 사용.
    /// 가로값이 오토레이아웃으로 변경되는 경우에 사용.
    ///
    /// - Parameters:
    ///   - imageUrl: 사용하고자 하는 이미지의
    public init(imageUrl: String = "", width: CGFloat) {
        self.imageUrl = imageUrl
        viewWidth = width

        super.init(frame: .zero)
        setupProperties()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Setup UI

extension FlexibleImageView {
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
                let aspectRatio = imageSize.height / imageSize.width
                snp.remakeConstraints { make in
                    make.width.equalTo(viewWidth) // 너비 고정
                    make.height.equalTo(viewWidth * aspectRatio) // 높이 자동 조정
                }
            }
        }
    }
}
