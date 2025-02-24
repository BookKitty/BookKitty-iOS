//
//  WidthFixedImageView.swift
//  DesignSystem
//
//  Created by 임성수 on 2/4/25.
//

import SnapKit
import UIKit

public enum BookImageFixedWidth {
    case regular
    case large
}

public class WidthFixedImageView: UIImageView {
    // MARK: - Properties

    // MARK: - Public

    public var imageLink: String
    public var fixedWidth: CGFloat

    private var heightConstraint: Constraint?

    // MARK: - Lifecycle

    // MARK: - Initializer

    /// 너비가 고정된 이미지뷰.
    /// 책의 이미지를 표시하는데 사용.
    /// 두가지의 값 중 선택하여 사용합니다. ``BookImageFixedWidth`` 참고.
    ///
    /// - Parameters:
    ///   - imageLink: 사용하고자 하는 이미지의 주소값
    ///   - width: 책의 너비값 선택.
    public init(imageLink: String = "", width: BookImageFixedWidth) {
        self.imageLink = imageLink

        switch width {
        case .regular:
            fixedWidth = Vars.imageFixedWidth
        case .large:
            fixedWidth = Vars.imageFixedWidthLarge
        }

        super.init(frame: .zero)

        setupProperties()
        setupLayouts()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Setup UI

extension WidthFixedImageView {
    private func setupProperties() {
        contentMode = .scaleAspectFit
        clipsToBounds = true
        setupImage(imageLink: imageLink)
    }

    private func setupLayouts() {
        snp.makeConstraints { make in
            make.width.equalTo(fixedWidth)
        }
    }

    private func setDefaultImage() {
        if let defaultImage = UIImage(
            named: "DefaultBookImage",
            in: Bundle.module,
            compatibleWith: nil
        ) {
            let imageSize = defaultImage.size
            let aspectRatio = imageSize.height / imageSize.width
            let calculatedHeight = fixedWidth * aspectRatio

            if let constraint = heightConstraint {
                constraint.update(offset: calculatedHeight)
            } else {
                snp.makeConstraints { make in
                    heightConstraint = make.height.equalTo(calculatedHeight).constraint
                }
            }

            image = defaultImage
        }
    }
}

// MARK: - Public Methods

extension WidthFixedImageView {
    public func setRadius(to isRound: Bool) {
        layer.cornerRadius = isRound ? Vars.radiusMini : 0
    }

    public func setupImage(imageLink: String) {
        guard let url = URL(string: imageLink) else {
            setDefaultImage()
            return
        }

        kf.setImage(
            with: url,
            placeholder: UIImage(named: "DefaultBookImage", in: Bundle.module, compatibleWith: nil),
            options: [
                .transition(.fade(0.2)), // 부드러운 페이드 효과
                .cacheOriginalImage, // 원본 이미지 캐싱
            ],
            completionHandler: { [weak self] result in
                guard let self else {
                    return
                }

                switch result {
                case let .success(value):
                    let bookImage = value.image

                    // 이미지의 원본 비율에 맞춰 높이 조정
                    let imageSize = bookImage.size
                    let aspectRatio = imageSize.height / imageSize.width
                    let calculatedHeight = fixedWidth * aspectRatio

                    if let constraint = heightConstraint {
                        constraint.update(offset: calculatedHeight)
                    } else {
                        snp.makeConstraints { make in
                            heightConstraint = make.height.equalTo(calculatedHeight).constraint
                        }
                    }

                case .failure:
                    setDefaultImage()
                }
            }
        )
    }
}
