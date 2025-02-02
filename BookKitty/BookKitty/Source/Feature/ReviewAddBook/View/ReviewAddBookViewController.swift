//
//  ReviewAddBookViewController.swift
//  BookKitty
//  P-011
//
//  Created by 전성규 on 1/31/25.
//

import RxCocoa
import RxSwift
import SnapKit
import Then
import UIKit

final class ReviewAddBookViewController: BaseViewController {
    // MARK: Lifecycle

    init(viewModel: ReviewAddBookViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    override func bind() {
        let input = ReviewAddBookViewModel.Input(
            testButton02Trigger: testButton02.rx.tap.asObservable()
        )

        _ = viewModel.transform(input)
    }

    override func configureHierarchy() {
        [testLabel, testButton01, testButton02].forEach { view.addSubview($0) }
    }

    override func configureLayout() {
        testLabel.snp.makeConstraints { $0.center.equalToSuperview() }

        testButton01.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(testLabel.snp.bottom).offset(20.0)
            $0.width.equalTo(100.0)
        }

        testButton02.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(testButton01.snp.bottom).offset(20.0)
            $0.width.equalTo(100.0)
        }
    }

    // MARK: Private

    private let testLabel = UILabel().then {
        $0.text = "P-011"
        $0.font = .systemFont(ofSize: 30.0, weight: .bold)
    }

    private let testButton01 = UIButton().then {
        $0.setTitle("책 추가하기", for: .normal)
        $0.backgroundColor = .tintColor
    }

    private let testButton02 = UIButton().then {
        $0.setTitle("추가 완료", for: .normal)
        $0.backgroundColor = .tintColor
    }

    private let viewModel: ReviewAddBookViewModel
}

@available(iOS 17.0, *)
#Preview {
    ReviewAddBookViewController(viewModel: ReviewAddBookViewModel())
}
