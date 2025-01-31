//
//  AddBookViewController.swift
//  BookKitty
//  P-008
//
//  Created by 전성규 on 1/31/25.
//

import RxCocoa
import SnapKit
import Then
import UIKit

final class AddBookViewController: BaseViewController {
    // MARK: Lifecycle

    init(viewModel: AddBookViewModel) {
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
        let input = AddBookViewModel.Input(
            testButtonTigger: testButton.rx.tap.asObservable()
        )

        _ = viewModel.transform(input)
    }

    override func configureNavItem() {
        let barButtonItem = UIBarButtonItem(
            title: "제목 입력하기",
            style: .plain,
            target: nil,
            action: nil
        )

        navigationItem.rightBarButtonItem = barButtonItem
    }

    override func configureHierarchy() {
        [testLabel, testButton].forEach { view.addSubview($0) }
    }

    override func configureLayout() {
        testLabel.snp.makeConstraints { $0.center.equalToSuperview() }

        testButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(testLabel.snp.bottom).offset(20.0)
            $0.width.height.equalTo(80.0)
        }
    }

    // MARK: Private

    private let viewModel: AddBookViewModel

    private let testLabel = UILabel().then {
        $0.text = "P-008"
        $0.font = .systemFont(ofSize: 30.0, weight: .bold)
    }

    private let testButton = UIButton().then {
        $0.setTitle("사진찍기", for: .normal)
        $0.backgroundColor = .tintColor
    }
}

@available(iOS 17.0, *)
#Preview {
    AddBookViewController(viewModel: AddBookViewModel())
}
