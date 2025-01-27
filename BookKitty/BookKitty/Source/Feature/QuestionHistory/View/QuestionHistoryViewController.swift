//
//  QuestionHistoryViewController.swift
//  BookKitty
//  P-002
//
//  Created by 전성규 on 1/26/25.
//

import RxCocoa
import RxSwift
import SnapKit
import UIKit

final class QuestionHistoryViewController: BaseViewController {
    // MARK: Lifecycle

    init(viewModel: QuestionHistoryViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    override func bind() {
        let input = QuestionHistoryViewModel.Input(
            testButtonTapTrigger: testButton.rx.tap.asObservable()
        )

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
        }
    }

    // MARK: Private

    private var viewModel: QuestionHistoryViewModel

    private let testLabel: UILabel = {
        let label = UILabel()
        label.text = "P-002"
        label.font = .systemFont(ofSize: 30.0, weight: .bold)

        return label
    }()

    private let testButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .tintColor
        button.setTitle("Push P-007", for: .normal)
        button.layer.cornerRadius = 12.0

        return button
    }()
}

@available(iOS 17.0, *)
#Preview {
    let viewModel = QuestionHistoryViewModel()
    return QuestionHistoryViewController(viewModel: viewModel)
}
