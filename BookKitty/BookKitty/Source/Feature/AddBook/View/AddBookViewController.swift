//
//  AddBookViewController.swift
//  BookKitty
//
//  Created by 반성준 on 1/31/25.
//

import AVFoundation
import RxCocoa
import RxSwift
import SnapKit
import Then
import UIKit

final class AddBookViewController: BaseCameraViewController {
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

    // MARK: - UI Elements

    let backButton = UIButton().then {
        $0.setTitle("← 돌아가기", for: .normal)
        $0.setTitleColor(.systemTeal, for: .normal)
    }

    let manualAddButton = UIButton().then {
        $0.setTitle("제목 입력하기", for: .normal)
        $0.setTitleColor(.systemTeal, for: .normal)
    }

    let captureButton = UIButton().then {
        $0.setImage(UIImage(systemName: "camera.fill"), for: .normal)
        $0.tintColor = .white
        $0.backgroundColor = .systemTeal
        $0.layer.cornerRadius = 30
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

    private let viewModel: AddBookViewModel
    private let disposeBag = DisposeBag()
    private let manualTitleSubject = PublishSubject<String>()

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = .white
        [
            backButton,
            manualAddButton,
            cameraView, // ✅ BaseCameraViewController에서 상속받은 cameraView 사용
            captureButton,
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

        cameraView.snp.makeConstraints {
            $0.top.equalTo(backButton.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(300)
        }

        captureButton.snp.makeConstraints {
            $0.top.equalTo(cameraView.snp.bottom).offset(20)
            $0.centerX.equalToSuperview()
            $0.width.height.equalTo(60)
        }

        confirmButton.snp.makeConstraints {
            $0.top.equalTo(captureButton.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(50)
        }
    }

    // MARK: - ViewModel Binding

    private func bindViewModel() {
        let input = AddBookViewModel.Input(
            captureButtonTapped: captureButton.rx.tap.asObservable(),
            manualAddButtonTapped: manualTitleSubject.asObservable(),
            confirmButtonTapped: confirmButton.rx.tap.asObservable()
        )

        let output = viewModel.transform(input)

        output.navigateToReviewAddBook
            .bind { [weak self] _ in
                self?.dismiss(animated: true)
            }
            .disposed(by: disposeBag)

        output.showTitleInputPopup
            .bind { [weak self] in
                self?.showManualTitleInput()
            }
            .disposed(by: disposeBag)

        captureButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.capturePhoto()
            })
            .disposed(by: disposeBag)
    }

    private func showManualTitleInput() {
        let alert = UIAlertController(
            title: "책 제목 입력",
            message: "책 제목을 입력해주세요.",
            preferredStyle: .alert
        )
        alert.addTextField()
        let addAction = UIAlertAction(title: "추가", style: .default) { [weak self] _ in
            if let title = alert.textFields?.first?.text, !title.isEmpty {
                self?.manualTitleSubject.onNext(title)
            }
        }
        alert.addAction(addAction)
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        present(alert, animated: true)
    }
}
