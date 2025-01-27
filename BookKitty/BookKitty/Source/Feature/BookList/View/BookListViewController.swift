//
//  BookListViewController.swift
//  BookKitty
//  P-003
//
//  Created by 전성규 on 1/27/25.
//

import RxSwift
import SnapKit
import UIKit

final class BookListViewController: BaseViewController {
    // MARK: Lifecycle

    init(viewModel: BookListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    override func bind() {
        let input = BookListViewModel.Input(testButtonTapTrigger: testButton.rx.tap.asObservable())

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

    private let viewModel: BookListViewModel

    private let testLabel: UILabel = {
        let label = UILabel()
        label.text = "P-003"
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
