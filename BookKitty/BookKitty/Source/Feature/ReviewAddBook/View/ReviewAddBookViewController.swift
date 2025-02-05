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

    // MARK: Private Properties

    private let viewModel: ReviewAddBookViewModel

    private let backButton = UIButton().then {
        $0.setTitle("← 돌아가기", for: .normal)
        $0.setTitleColor(.systemTeal, for: .normal)
    }

    private let manualAddButton = UIButton().then {
        $0.setTitle("제목 입력하기", for: .normal)
        $0.setTitleColor(.systemTeal, for: .normal)
    }

    private let titleLabel = UILabel().then {
        $0.text = "촬영 결과"
        $0.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        $0.textAlignment = .center
    }

    private let bookListView = UITableView().then {
        $0.register(UITableViewCell.self, forCellReuseIdentifier: "BookCell")
    }

    private let addBookGuideLabel = UILabel().then {
        $0.text = "누락된 책이 있나요?\n책의 제목을 입력하여 직접 책을 추가하세요."
        $0.textAlignment = .center
        $0.font = .systemFont(ofSize: 14, weight: .regular)
        $0.textColor = .gray
        $0.numberOfLines = 2
    }

    private let addBookButton = UIButton().then {
        $0.setTitle("+ 책 추가하기", for: .normal)
        $0.setTitleColor(.systemTeal, for: .normal)
    }

    private let confirmButton = UIButton().then {
        $0.setTitle("추가 완료", for: .normal)
        $0.setTitleColor(.white, for: .normal)
        $0.backgroundColor = .systemGreen
        $0.layer.cornerRadius = 8
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = .white
        [
            backButton,
            manualAddButton,
            titleLabel,
            bookListView,
            addBookGuideLabel,
            addBookButton,
            confirmButton,
        ].forEach { view.addSubview($0) }
    }

    private func setupConstraints() {
        backButton.snp.makeConstraints {
            $0.top.leading.equalTo(view.safeAreaLayoutGuide).inset(16)
        }

        manualAddButton.snp.makeConstraints {
            $0.top.trailing.equalTo(view.safeAreaLayoutGuide).inset(16)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(backButton.snp.bottom).offset(10)
            $0.centerX.equalToSuperview()
        }

        bookListView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalTo(addBookGuideLabel.snp.top).offset(-10)
        }

        addBookGuideLabel.snp.makeConstraints {
            $0.bottom.equalTo(addBookButton.snp.top).offset(-10)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        addBookButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalTo(confirmButton.snp.top).offset(-10)
        }

        confirmButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            $0.height.equalTo(50)
        }
    }

    // MARK: - Bind ViewModel

    private func bindViewModel() {
        let input = ReviewAddBookViewModel.Input(
            confirmButtonTapped: confirmButton.rx.tap.asObservable(),
            addBookButtonTapped: addBookButton.rx.tap.asObservable(),
            deleteBookTapped: bookListView.rx.itemDeleted.map(\.row) // ✅ IndexPath → Int 변환
        )

        let output = viewModel.transform(input)

        output.bookList
            .bind(to: bookListView.rx.items(
                cellIdentifier: "BookCell",
                cellType: UITableViewCell.self
            )) { _, book, cell in
                cell.textLabel?.text = book
            }
            .disposed(by: super.disposeBag) // ✅ `super.disposeBag` 사용

        output.navigateToBookList
            .bind { [weak self] in
                self?.dismiss(animated: true)
            }
            .disposed(by: super.disposeBag) // ✅ `super.disposeBag` 사용

        output.showTitleInputPopup
            .bind { [weak self] in
                self?.showTitleInputPopup()
            }
            .disposed(by: super.disposeBag) // ✅ `super.disposeBag` 사용
    }

    private func showTitleInputPopup() {
        let alert = UIAlertController(
            title: "책 제목 입력",
            message: "책 제목을 입력해주세요.",
            preferredStyle: .alert
        )
        alert.addTextField()

        let addAction = UIAlertAction(title: "추가", style: .default) { [weak self] _ in
            if let title = alert.textFields?.first?.text, !title.isEmpty {
                self?.viewModel.addBook(title)
            }
        }
        let cancelAction = UIAlertAction(title: "취소", style: .cancel)

        alert.addAction(addAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }
}
