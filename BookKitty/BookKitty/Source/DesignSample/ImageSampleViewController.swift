//
//  ImageSampleViewController.swift
//  BookKitty
//
//  Created by 임성수 on 2/4/25.
//

import DesignSystem
import SnapKit
import Then
import UIKit

class ImageSampleViewController: BaseViewController {
    // MARK: - Properties

    // MARK: - Internal

    let scrollView = UIScrollView()
    let contentView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = Vars.spacing20
        $0.distribution = .equalSpacing
        $0.alignment = .leading
    }

    let noImageBook = WidthFixedImageView(width: .regular)
    let widthFixedBook = WidthFixedImageView(
        imageLink:
        """
        https://search1.kakaocdn.net/thumb/R120x174.q85/?fname=http%3A%2F%2Ft1.\
        daumcdn.net%2Flbook%2Fimage%2F5213380%3Ftimestamp%3D20240904145528
        """,
        width: .regular
    )

    let largeWidthFixedBook = WidthFixedImageView(
        imageLink:
        """
        https://search1.kakaocdn.net/thumb/R120x174.q85/?fname=http%3A%2F%2Ft1.\
        daumcdn.net%2Flbook%2Fimage%2F5213380%3Ftimestamp%3D20240904145528"
        """,
        width: .large
    )

    let flexibleBook = FlexibleImageView(
        imageLink: "https://shopping-phinf.pstatic.net/main_4718969/47189696637.20240421070849.jpg",
        width: 150.0
    )

    let flexibleBook2 = FlexibleImageView(
        imageLink: "",
        width: 180.0
    )

    let noImageBook2 = HeightFixedImageView(height: .regular)
    let heightFixedBook = HeightFixedImageView(
        imageLink:
        """
        https://search1.kakaocdn.net/thumb/R120x174.q85/?fname=http%3A%2F%2Ft1.daumcdn.net%2Flbook%2Fimage%2F1634926%3Ftimestamp%3D20221025125823
        """,
        height: .small
    )

    // MARK: - Lifecycle

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
        ].forEach { contentView.addArrangedSubview($0) }
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
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    ImageSampleViewController()
}
