//
//  AddBookViewController.swift
//  BookKitty
//
//  Created by 반성준 on 1/31/25.
//

import RxCocoa
import RxSwift
import SnapKit
import Then
import UIKit

final class AddBookViewController: UIViewController {
    // MARK: Lifecycle

    // MARK: - Initialization

    init(viewModel: AddBookViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    // MARK: - Internal UI Elements (Coordinator에서 접근 가능하도록 설정)

    let captureButton = UIButton().then {
        $0.setImage(UIImage(systemName: "camera.fill"), for: .normal)
        $0.tintColor = .white
        $0.backgroundColor = .systemBlue
        $0.layer.cornerRadius = 30
    }

    let addBookButton = UIButton().then {
        $0.setTitle("+ 책 추가하기", for: .normal)
        $0.setTitleColor(.systemBlue, for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
    }

    let confirmButton = UIButton().then {
        $0.setTitle("추가 완료", for: .normal)
        $0.setTitleColor(.white, for: .normal)
        $0.backgroundColor = .systemGreen
        $0.layer.cornerRadius = 8
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        bindViewModel()
    }

    // MARK: Private

    // MARK: - Private Properties

    private let viewModel: AddBookViewModel
    private let disposeBag = DisposeBag()

    private let cameraView = UIView().then {
        $0.backgroundColor = .lightGray
        $0.layer.cornerRadius = 8
    }

    private let guideLabel = UILabel().then {
        $0.text = "책의 정보를 파악할 수 있도록 촬영하세요."
        $0.textAlignment = .center
        $0.font = .systemFont(ofSize: 14, weight: .regular)
        $0.textColor = .gray
    }

    private let bookTableView = UITableView().then {
        $0.register(UITableViewCell.self, forCellReuseIdentifier: "BookCell")
        $0.isHidden = true // ✅ 초기에는 숨김 상태
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = .white
        [cameraView, guideLabel, captureButton, bookTableView, addBookButton, confirmButton]
            .forEach { view.addSubview($0) }
    }

    private func setupConstraints() {
        cameraView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(300)
        }

        guideLabel.snp.makeConstraints {
            $0.top.equalTo(cameraView.snp.bottom).offset(10)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        captureButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(guideLabel.snp.bottom).offset(15)
            $0.width.height.equalTo(60)
        }

        bookTableView.snp.makeConstraints {
            $0.top.equalTo(captureButton.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalTo(addBookButton.snp.top).offset(-10)
        }

        addBookButton.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(20)
            $0.bottom.equalTo(confirmButton.snp.top).offset(-10)
        }

        confirmButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-10)
            $0.height.equalTo(50)
        }
    }

    // MARK: - ViewModel Binding

    private func bindViewModel() {
        let input = AddBookViewModel.Input(
            captureButtonTapped: captureButton.rx.tap.asObservable(),
            manualAddButtonTapped: addBookButton.rx.tap.asObservable(),
            confirmButtonTapped: confirmButton.rx.tap.asObservable()
        )

        let output = viewModel.transform(input)

        // ✅ TableView에 bookList 바인딩
        output.bookList
            .do(onNext: { [weak self] books in
                self?.bookTableView.isHidden = books.isEmpty
            })
            .bind(to: bookTableView.rx.items(
                cellIdentifier: "BookCell",
                cellType: UITableViewCell.self
            )) { _, book, cell in
                cell.textLabel?.text = book
            }
            .disposed(by: disposeBag)
    }
}
