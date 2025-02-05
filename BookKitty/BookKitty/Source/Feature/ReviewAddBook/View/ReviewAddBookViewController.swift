//
//  ReviewAddBookViewController.swift
//  BookKitty
//
//  Created by 반성준 on 1/31/25.
//

import RxCocoa
import RxSwift
import SnapKit
import Then
import UIKit

final class ReviewAddBookViewController: BaseViewController {
    // MARK: Lifecycle

    // MARK: - Initialization

    init(viewModel: ReviewAddBookViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        bindViewModel()
    }

    // MARK: Private

    private let viewModel: ReviewAddBookViewModel

    // ✅ `BaseViewController`의 `disposeBag`을 직접 사용하도록 변경
    // ⚠️ 더 이상 `disposeBag`을 재선언하지 않음
    // ⚠️ `super.disposeBag`을 사용해 명확하게 해결

    // MARK: - UI Elements

    private let testLabel = UILabel().then {
        $0.text = "책 추가 화면"
        $0.font = .systemFont(ofSize: 24, weight: .bold)
        $0.textAlignment = .center
    }

    private let addBookButton = UIButton().then {
        $0.setTitle("책 추가하기", for: .normal)
        $0.backgroundColor = .systemBlue
        $0.layer.cornerRadius = 8
    }

    private let confirmButton = UIButton().then {
        $0.setTitle("추가 완료", for: .normal)
        $0.backgroundColor = .systemGreen
        $0.layer.cornerRadius = 8
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.addSubview(testLabel)
        view.addSubview(addBookButton)
        view.addSubview(confirmButton)
    }

    private func setupConstraints() {
        testLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }

        addBookButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(testLabel.snp.bottom).offset(20)
            $0.width.equalTo(150)
        }

        confirmButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(addBookButton.snp.bottom).offset(20)
            $0.width.equalTo(150)
        }
    }

    // MARK: - Bind ViewModel

    private func bindViewModel() {
        let input = ReviewAddBookViewModel.Input(
            confirmButtonTapped: confirmButton.rx.tap.asObservable()
        )

        let output = viewModel.transform(input)

        output.navigateToBookList
            .bind { [weak self] in
                self?.dismiss(animated: true)
            }
            .disposed(by: super.disposeBag) // ✅ `super.disposeBag`을 명확하게 사용
    }
}
