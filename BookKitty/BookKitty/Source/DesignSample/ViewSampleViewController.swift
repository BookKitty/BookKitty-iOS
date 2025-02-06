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
    let verticalScrollView = UIScrollView()
    let contentView = UIView()

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
        isOwened: true
    )

    let recBookUnowned = RecommendedBookView(
        bookTitle: "내가 안 소유한 책. 여튼 가지고 있지 않은 그런 책.",
        bookAuthor: "김형석 외 절대 다수. 매우 많은 사람들. 내배캠 사람들.",
        imageUrl: "https://shopping-phinf.pstatic.net/main_3246426/32464267002.20221230072620.jpg",
        isOwened: false
    )

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
        ].forEach { contentView.addSubview($0) }

        horizontalScrollView.addSubview(horizontalStackView)

        [
            recBookOwned,
            recBookUnowned,
        ].forEach { horizontalStackView.addArrangedSubview($0) }
    }

    private func setupProperties() {
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
    }
}

@available(iOS 17.0, *)
#Preview {
    ViewSampleViewController()
}
