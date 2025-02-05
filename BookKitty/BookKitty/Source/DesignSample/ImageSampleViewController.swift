//
//  ImageSampleViewController.swift
//  BookKitty
//
//  Created by MaxBook on 2/4/25.
//

import DesignSystem
import SnapKit
import Then
import UIKit

class ImageSampleViewController: BaseViewController {
    let scrollView = UIScrollView()
    let contentView = UIView()

    let noImageBook = WidthFixedImageView(width: .regular)
    let widthFixedBook = WidthFixedImageView(
        imageUrl:
        """
        https://search1.kakaocdn.net/thumb/R120x174.q85/?fname=http%3A%2F%2Ft1.\
        daumcdn.net%2Flbook%2Fimage%2F5213380%3Ftimestamp%3D20240904145528
        """,
        width: .regular
    )

    let largeWidthFixedBook = WidthFixedImageView(
        imageUrl:
        """
        https://search1.kakaocdn.net/thumb/R120x174.q85/?fname=http%3A%2F%2Ft1.\
        daumcdn.net%2Flbook%2Fimage%2F5213380%3Ftimestamp%3D20240904145528"
        """,
        width: .large
    )

    let flexibleBook = FlexibleImageView(
        imageUrl: "https://shopping-phinf.pstatic.net/main_4718969/47189696637.20240421070849.jpg",
        width: 150.0
    )

    let flexibleBook2 = FlexibleImageView(
        imageUrl: "",
        width: 180.0
    )

    let noImageBook2 = HeightFixedImageView(height: .regular)
    let heightFixedBook = HeightFixedImageView(
        imageUrl:
        """
        https://search1.kakaocdn.net/thumb/R120x174.q85/?fname=http%3A%2F%2Ft1.\
        daumcdn.net%2Flbook%2Fimage%2F5213380%3Ftimestamp%3D20240904145528
        """,
        height: .small
    )

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupProperties()
        setupLayouts()
        updateLayouts()
    }
}

// MARK: - UI Configure

extension ImageSampleViewController {
    private func setupViews() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        [
            noImageBook,
            widthFixedBook,
            largeWidthFixedBook,
            flexibleBook,
            flexibleBook2,
            noImageBook2,
            heightFixedBook,
        ].forEach { contentView.addSubview($0) }
    }

    private func setupProperties() {
        view.backgroundColor = Colors.background0
    }

    private func setupLayouts() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }

        noImageBook.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(Vars.spacing72)
            make.leading.equalToSuperview().inset(Vars.paddingReg)
        }

        widthFixedBook.snp.makeConstraints { make in
            make.top.equalTo(noImageBook.snp.bottom).offset(Vars.spacing24)
            make.leading.equalToSuperview().inset(Vars.paddingReg)
        }

        largeWidthFixedBook.snp.makeConstraints { make in
            make.top.equalTo(widthFixedBook.snp.bottom).offset(Vars.spacing24)
            make.leading.equalToSuperview().inset(Vars.paddingReg)
        }

        flexibleBook.snp.makeConstraints { make in
            make.top.equalTo(largeWidthFixedBook.snp.bottom).offset(Vars.spacing72)
            make.leading.equalToSuperview().inset(Vars.paddingReg)
        }

        flexibleBook2.snp.makeConstraints { make in
            make.top.equalTo(flexibleBook.snp.bottom).offset(Vars.spacing24)
            make.leading.equalToSuperview().inset(Vars.paddingReg)
        }

        noImageBook2.snp.makeConstraints { make in
            make.top.equalTo(flexibleBook2.snp.bottom).offset(Vars.spacing24)
            make.leading.equalToSuperview().inset(Vars.paddingReg)
        }

        heightFixedBook.snp.makeConstraints { make in
            make.top.equalTo(noImageBook2.snp.bottom).offset(Vars.spacing24)
            make.leading.equalToSuperview().inset(Vars.paddingReg)
            make.bottom.equalToSuperview().inset(Vars.spacing48)
        }
    }

    /// 모든 이미지뷰의 로딩 완료 후 레이아웃 재설정
    private func updateLayouts() {
        let allImageViews: [ImageLoadableView] = [
            noImageBook,
            widthFixedBook,
            largeWidthFixedBook,
            noImageBook2,
            heightFixedBook,
        ]
        var loadedImageCount = 0

        for imageView in allImageViews {
            imageView.onImageLoaded = { [weak self] in
                loadedImageCount += 1
                if loadedImageCount == allImageViews.count {
                    self?.setupLayouts() // 모든 이미지 로딩 후 레이아웃 업데이트
                }
            }
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    ImageSampleViewController()
}
