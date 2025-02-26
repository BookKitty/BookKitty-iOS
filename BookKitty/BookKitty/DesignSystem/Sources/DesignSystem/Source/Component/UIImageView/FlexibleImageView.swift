//
//  FlexibleImageView.swift
//  DesignSystem
//
//  Created by 임성수 on 2/4/25.
//

import NeoImage
import SnapKit
import UIKit

public class FlexibleImageView: UIImageView {
    // MARK: - Properties

    // MARK: - Public

    public var imageLink: String
    public var viewWidth: CGFloat

    private var heightConstraint: Constraint?

    // MARK: - Lifecycle

    // MARK: - Initializer

    /// 가로값 기준 세로값이 정해지는 이미지뷰.
    /// 책의 이미지를 표시하는데 사용.
    /// 가로값이 오토레이아웃으로 변경되는 경우에 사용.
    ///
    /// - Parameters:
    ///   - imageLink: 사용하고자 하는 이미지의
    public init(imageLink: String = "", width: CGFloat) {
        self.imageLink = imageLink
        viewWidth = width

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

extension FlexibleImageView {
    private func setupProperties() {
        contentMode = .scaleAspectFit
        clipsToBounds = true
        setupImage(imageLink: imageLink)
    }

    private func setupLayouts() {
        snp.makeConstraints { make in
            make.width.equalTo(viewWidth)
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
            let calculatedHeight = viewWidth * aspectRatio

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

extension FlexibleImageView {
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

                    // 이미지의 원본 비율에 맞춰 높이 조정
                    let imageSize = bookImage.size
                    let aspectRatio = imageSize.height / imageSize.width
                    let calculatedHeight = viewWidth * aspectRatio

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
