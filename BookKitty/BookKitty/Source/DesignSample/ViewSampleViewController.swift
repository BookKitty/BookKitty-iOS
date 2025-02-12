//
//  ViewSampleViewController.swift
//  BookKitty
//
//  Created by 임성수 on 2/4/25.
//

//
//  EtcSampleViewController.swift
//  BookKitty
//
//  Created by 임성수 on 2/4/25.
//

import DesignSystem
import SnapKit
import Then
import UIKit

class ViewSampleViewController: BaseViewController {
    // MARK: - Properties

    // MARK: - Internal

    let verticalScrollView = UIScrollView()
    let contentView = UIView()
    let lottieView =
        LottieView(imageLink: "https://cdn.lottielab.com/l/9pByBsRpAhjWrh.json")

    let horizontalScrollView = UIScrollView()
    let horizontalStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.distribution = .equalSpacing
        $0.spacing = Vars.spacing12
        $0.alignment = .fill
    }

    let recBookOwned = RecommendedBookView(
        bookTitle: "내가 소유한 책",
        bookAuthor: "권승용",
        imageUrl: "https://shopping-phinf.pstatic.net/main_3249784/32497843121.20221230071919.jpg",
        isOwned: true
    )

    let recBookUnowned = RecommendedBookView(
        bookTitle: "내가 안 소유한 책. 여튼 가지고 있지 않은 그런 책.",
        bookAuthor: "김형석 외 절대 다수. 매우 많은 사람들. 내배캠 사람들.",
        imageUrl: "https://shopping-phinf.pstatic.net/main_3246426/32464267002.20221230072620.jpg",
        isOwned: false
    )

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupProperties()
        setupLayouts()
    }
}

// MARK: - UI Configure

extension ViewSampleViewController {
    private func setupViews() {
        view.addSubview(verticalScrollView)
        verticalScrollView.addSubview(contentView)

        [
            horizontalScrollView,
            lottieView,
        ].forEach { contentView.addSubview($0) }

        horizontalScrollView.addSubview(horizontalStackView)

        [
            recBookOwned,
            recBookUnowned,
        ].forEach { horizontalStackView.addArrangedSubview($0) }
    }

    private func setupProperties() {
        let apiKey: String = {
            guard let apiKey = Bundle.main
                .object(forInfoDictionaryKey: "TEST_SAMPLE_TXT") as? String else {
                fatalError("TEST_SAMPLE_TXT not found in Info.plist")
            }
            return apiKey
        }()

        print(apiKey)
        view.backgroundColor = Colors.brandMain30
    }

    private func setupLayouts() {
        verticalScrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
            make.bottom.equalTo(horizontalScrollView.snp.bottom).offset(Vars.spacing20)
        }

        horizontalScrollView.snp.makeConstraints { make in
            make.height.equalTo(500)
            make.top.equalToSuperview().inset(Vars.spacing72)
            make.leading.trailing.equalToSuperview()
        }

        horizontalStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(Vars.paddingReg)
        }

        lottieView.snp.makeConstraints { make in
            make.top.equalTo(horizontalScrollView.snp.bottom).offset(Vars.spacing48)
            make.leading.trailing.equalToSuperview().inset(Vars.paddingReg)
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    ViewSampleViewController()
}
