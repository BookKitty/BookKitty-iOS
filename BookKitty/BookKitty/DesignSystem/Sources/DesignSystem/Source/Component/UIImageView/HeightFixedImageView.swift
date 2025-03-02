//
//  HeightFixedImageView.swift
//  DesignSystem
//
//  Created by 임성수 on 2/4/25.
//

import NeoImage
import SnapKit
import UIKit

public enum BookImageFixedHeight {
    case regular
    case small
    case mini
}

public class HeightFixedImageView: UIImageView {
    // MARK: - Properties

    // MARK: - Public

    public var imageLink: String
    public var fixedHeight: CGFloat

    private var widthConstraint: Constraint?

    // MARK: - Lifecycle

    // MARK: - Initializer

    /// 높이가 고정된 이미지뷰.
    /// 책 이미지를 표시하는데 사용되며, 높이값은 ``BookImageFixedHeight`` 에 따라 정해집니다. 다음 세가지 수치가 있습니다.
    /// ``Vars.imageFixedHeight``, ``Vars.imageFixedHeightSmall``, ``Vars.imageFixedHeightMini``
    ///
    /// - Parameters:
    ///   - imageLink: 사용하고자 하는 이미지의 URL
    ///   - height: 책의 높이값 선택
    public init(imageLink: String = "", height: BookImageFixedHeight) {
        self.imageLink = imageLink

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
}

// MARK: - Setup UI

extension HeightFixedImageView {
    private func setupProperties() {
        contentMode = .scaleAspectFit
        clipsToBounds = true
        setupImage(imageLink: imageLink)
    }

    private func setupLayouts() {
        snp.makeConstraints { make in
            make.height.equalTo(fixedHeight)
        }
    }

    private func setDefaultImage() {
        if let defaultImage = UIImage(
            named: "DefaultBookImage",
            in: Bundle.module,
            compatibleWith: nil
        ) {
            let imageSize = defaultImage.size
            let aspectRatio = min(imageSize.width / imageSize.height, 1.0)
            let calculatedWidth = fixedHeight * aspectRatio

            if let constraint = widthConstraint {
                constraint.update(offset: calculatedWidth)
            } else {
                snp.makeConstraints { make in
                    widthConstraint = make.width.equalTo(calculatedWidth).constraint
                }
            }

            image = defaultImage
        }
    }
}

// MARK: - Methods

extension HeightFixedImageView {
    public func setRadius(to isRound: Bool) {
        layer.cornerRadius = isRound ? Vars.radiusMini : 0
    }

    public func setupImage(imageLink: String) {
        guard let url = URL(string: imageLink) else {
            setDefaultImage()
            return
        }

        let options = NeoImageOptions(
            transition: .fade(0.2),
            retryStrategy: .times(3)
        )

        neo.setImage(
            with: url,
            placeholder: UIImage(named: "DefaultBookImage", in: Bundle.module, compatibleWith: nil),
            options: options,
            completion: { [weak self] result in
                guard let self else {
                    return
                }

                switch result {
                case let .success(value):
                    let bookImage = value.image

                    // 이미지의 원본 비율에 맞춰 너비 조정
                    let imageSize = bookImage.size
                    let aspectRatio = min(imageSize.width / imageSize.height, 1.0)
                    let calculatedWidth = fixedHeight * aspectRatio

                    if let constraint = widthConstraint {
                        constraint.update(offset: calculatedWidth)
                    } else {
                        snp.makeConstraints { make in
                            widthConstraint = make.width.equalTo(calculatedWidth).constraint
                        }
                    }

                case .failure:
                    setDefaultImage()
                }
            }
        )
    }
}
