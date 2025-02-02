//
//  BookDetailViewController.swift
//  BookKitty
//  P-006
//
//  Created by 전성규 on 1/27/25.
//

import SnapKit
import UIKit

final class BookDetailViewController: BaseViewController {
    // MARK: Lifecycle

    init(viewModel: BookDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.navigationBar.isHidden = false
    }

    override func bind() {
        let input = BookDetailViewModel.Input(viewDidLoad: viewDidLoadRelay.asObservable())

        _ = viewModel.transform(input)
    }

    override func configureHierarchy() {
        [testLabel].forEach { view.addSubview($0) }
    }

    override func configureLayout() {
        testLabel.snp.makeConstraints { $0.center.equalToSuperview() }
    }

    // MARK: Private

    private let viewModel: BookDetailViewModel

    private let testLabel: UILabel = {
        let label = UILabel()
        label.text = "P-006"
        label.font = .systemFont(ofSize: 30.0, weight: .bold)

        return label
    }()
}

@available(iOS 17.0, *)
#Preview {
    BookDetailViewController(viewModel: BookDetailViewModel())
}
