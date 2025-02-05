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

    let captureButton = UIButton().then {
        let config = UIImage.SymbolConfiguration(pointSize: 36, weight: .bold)
        let cameraImage = UIImage(systemName: "camera.fill", withConfiguration: config)

        $0.setImage(cameraImage, for: .normal)
        $0.tintColor = .white
        $0.backgroundColor = .black
        $0.layer.cornerRadius = 36
    }

    let manualAddButton = UIButton().then {
        $0.setTitle("제목 입력하기", for: .normal)
        $0.setTitleColor(.systemTeal, for: .normal)
        $0.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = cameraView.bounds
    }

    // MARK: Private

    private let viewModel: AddBookViewModel
    private let disposeBag = DisposeBag()
    private let manualTitleSubject = PublishSubject<String>()

    // MARK: - UI Elements

    private let backButton = UIButton().then {
        $0.setTitle("← 돌아가기", for: .normal)
        $0.setTitleColor(.systemTeal, for: .normal)
    }

    private let titleLabel = UILabel().then {
        $0.text = "새로운 책 추가하기"
        $0.font = UIFont.boldSystemFont(ofSize: 20)
        $0.textColor = .black
        $0.textAlignment = .center
    }

    private let cameraContainerView = UIView().then {
        $0.backgroundColor = .black
        $0.layer.cornerRadius = 10
    }

    private let yellowInfoView = UIView().then {
        $0.backgroundColor = UIColor.systemYellow.withAlphaComponent(0.4) // ✅ 더 연하게 & 투명하게 설정
        $0.layer.cornerRadius = 10
    }

    private let infoLabel = UILabel().then {
        $0.text = "책의 정보를 파악할 수 있는 책 한권의 겉면\n혹은 여러 권의 책이 꽂혀 있는 책장의 사진을 찍어주세요."
        $0.font = UIFont.systemFont(ofSize: 14)
        $0.textColor = .black
        $0.numberOfLines = 2
        $0.textAlignment = .center
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = .white

        view.addSubview(backButton)
        view.addSubview(manualAddButton) // ✅ "제목 입력하기" 버튼을 우측 상단으로 이동
        view.addSubview(titleLabel)
        view.addSubview(cameraContainerView)
        cameraContainerView.addSubview(cameraView)
        view.addSubview(yellowInfoView)
        yellowInfoView.addSubview(infoLabel)
        view.addSubview(captureButton)
        view.addSubview(confirmButton)
    }

    private func setupConstraints() {
        backButton.snp.makeConstraints {
            $0.top.leading.equalTo(view.safeAreaLayoutGuide).inset(16)
        }

        manualAddButton.snp.makeConstraints {
            $0.top.trailing.equalTo(view.safeAreaLayoutGuide).inset(16) // ✅ 우측 상단에 배치
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(backButton.snp.bottom).offset(10)
            $0.centerX.equalToSuperview()
        }

        cameraContainerView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(20)
            $0.centerX.equalToSuperview()
            $0.width.height.equalTo(402)
        }

        cameraView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        yellowInfoView.snp.makeConstraints {
            $0.top.equalTo(cameraContainerView.snp.bottom) // ✅ 카메라 바로 밑에 붙이기
            $0.centerX.equalToSuperview()
            $0.width.equalTo(402)
            $0.height.equalTo(70) // ✅ 더 얇게 조정
        }

        infoLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(10)
        }

        captureButton.snp.makeConstraints {
            $0.top.equalTo(yellowInfoView.snp.bottom).offset(20)
            $0.centerX.equalToSuperview()
            $0.width.height.equalTo(72)
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
        let cancelAction = UIAlertAction(title: "취소", style: .cancel)

        alert.addAction(addAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }
}
