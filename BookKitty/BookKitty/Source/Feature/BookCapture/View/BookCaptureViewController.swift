//
//  BookCaptureViewController.swift
//  BookKitty
//
//  Created by 반성준 on 2/5/25.
//

import AVFoundation
import RxCocoa
import RxSwift
import SnapKit
import Then
import UIKit

final class BookCaptureViewController: BaseCameraViewController {
    // MARK: Lifecycle

    init(viewModel: BookCaptureViewModel) {
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

    private let viewModel: BookCaptureViewModel
    private let disposeBag = DisposeBag()
    private let enteredTitle = PublishSubject<String>()

    // MARK: - UI Components

    private let backButton = UIButton().then {
        $0.setTitle("← 돌아가기", for: .normal)
        $0.setTitleColor(.systemTeal, for: .normal)
    }

    private let manualAddButton = UIButton().then {
        $0.setTitle("제목 입력하기", for: .normal)
        $0.setTitleColor(.systemTeal, for: .normal)
    }

    private let titleLabel = UILabel().then {
        $0.text = "새로운 책 추가하기"
        $0.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        $0.textAlignment = .center
    }

    private let descriptionLabel = UILabel().then {
        $0.text = "책의 정보를 파악할 수 있는 책 한권의 겉면 혹은 여러 권의 책이 꽂혀 있는 책장의 사진을 찍어주세요."
        $0.font = UIFont.systemFont(ofSize: 14)
        $0.textAlignment = .center
        $0.numberOfLines = 2
    }

    private let captureButton = UIButton().then {
        $0.setImage(UIImage(systemName: "camera.fill"), for: .normal)
        $0.tintColor = .white
        $0.backgroundColor = .systemBlue
        $0.layer.cornerRadius = 30
    }

    private let confirmButton = UIButton().then {
        $0.setTitle("확인", for: .normal)
        $0.backgroundColor = .systemGreen
        $0.setTitleColor(.white, for: .normal)
        $0.layer.cornerRadius = 8
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = .white
        [
            backButton,
            manualAddButton,
            titleLabel,
            cameraView, // ✅ BaseCameraViewController에서 상속받은 cameraView 사용
            descriptionLabel,
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

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(backButton.snp.bottom).offset(10)
            $0.centerX.equalToSuperview()
        }

        cameraView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(300)
        }

        descriptionLabel.snp.makeConstraints {
            $0.top.equalTo(cameraView.snp.bottom).offset(10)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        captureButton.snp.makeConstraints {
            $0.top.equalTo(descriptionLabel.snp.bottom).offset(20)
            $0.centerX.equalToSuperview()
            $0.width.height.equalTo(60)
        }

        confirmButton.snp.makeConstraints {
            $0.top.equalTo(captureButton.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(44)
        }
    }

    // MARK: - ViewModel Binding

    private func bindViewModel() {
        let input = BookCaptureViewModel.Input(
            captureButtonTapped: captureButton.rx.tap.asObservable(),
            manualAddButtonTapped: manualAddButton.rx.tap.asObservable(),
            confirmButtonTapped: confirmButton.rx.tap.asObservable(),
            enteredTitle: enteredTitle.asObservable()
        )

        let output = viewModel.transform(input)

        output.navigateToReview
            .bind { [weak self] bookList in
                self?.navigateToReview(bookList: bookList)
            }
            .disposed(by: disposeBag)

        output.showTitleInputPopup
            .bind { [weak self] in
                self?.showTitleInputPopup()
            }
            .disposed(by: disposeBag)

        captureButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.capturePhoto()
            }) // ✅ BaseCameraViewController에서 상속받음
            .disposed(by: disposeBag)
    }

    private func navigateToReview(bookList: [String]) {
        let books = bookList.map { title in
            Book(
                isbn: "",
                title: title,
                author: "알 수 없음",
                publisher: "알 수 없음",
                thumbnailUrl: nil
            )
        }

        let reviewViewModel = ReviewAddBookViewModel(initialBookList: books)
        let reviewViewController = ReviewAddBookViewController(viewModel: reviewViewModel)
        navigationController?.pushViewController(reviewViewController, animated: true)
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
                self?.enteredTitle.onNext(title)
            }
        }
        let cancelAction = UIAlertAction(title: "취소", style: .cancel)

        alert.addAction(addAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }
}
