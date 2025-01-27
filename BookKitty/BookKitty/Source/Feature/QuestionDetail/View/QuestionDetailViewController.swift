//
//  QuestionDetailViewController.swift
//  BookKitty
//  P-007
//
//  Created by 전성규 on 1/26/25.
//

import SnapKit
import UIKit

final class QuestionDetailViewController: BaseViewController {
    // MARK: Lifecycle

    init(viewModel: QuestionDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    let viewModel: QuestionDetailViewModel

    override func bind() {
        let input = QuestionDetailViewModel
            .Input(testButtonTapTrigger: testButton.rx.tap.asObservable())

        _ = viewModel.transform(input)
    }

    override func configureHierarchy() {
        [testLabel, testButton].forEach { view.addSubview($0) }
    }

    override func configureLayout() {
        testLabel.snp.makeConstraints { $0.center.equalToSuperview() }

        testButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(testLabel.snp.bottom).offset(20.0)
            $0.width.height.equalTo(150.0)
        }
    }

    // MARK: Private

    private let testLabel: UILabel = {
        let label = UILabel()
        label.text = "P-007"
        label.font = .systemFont(ofSize: 30.0, weight: .bold)

        return label
    }()

    private let testButton: UIButton = {
        let button = UIButton()
        button.setTitle("Book Thumbnail", for: .normal)
        button.backgroundColor = .tintColor

        return button
    }()
}
