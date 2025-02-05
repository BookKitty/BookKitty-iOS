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

final class AddBookViewController: UIViewController, AVCapturePhotoCaptureDelegate {
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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkCameraPermission { granted in
            if granted {
                self.setupCamera()
            } else {
                self.showPermissionAlert()
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = cameraView.bounds
    }

    // MARK: Private

    // MARK: Private Properties

    private let viewModel: AddBookViewModel
    private let disposeBag = DisposeBag()
    private let captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let captureOutput = AVCapturePhotoOutput()
    private let manualTitleSubject = PublishSubject<String>()

    // MARK: - UI Elements

    private let cameraView = UIView().then {
        $0.backgroundColor = .black
        $0.layer.cornerRadius = 8
        $0.clipsToBounds = true
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = .white
        [
            backButton,
            manualAddButton,
            cameraView,
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

    // MARK: - Camera Setup

    private func checkCameraPermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async { completion(granted) }
            }
        default:
            completion(false)
        }
    }

    private func showPermissionAlert() {
        let alert = UIAlertController(
            title: "카메라 권한 필요",
            message: "책을 촬영하려면 설정에서 카메라 접근 권한을 허용해주세요.",
            preferredStyle: .alert
        )

        let settingsAction = UIAlertAction(title: "설정으로 이동", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        }
        alert.addAction(settingsAction)
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        present(alert, animated: true)
    }

    private func setupCamera() {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let captureDevice = AVCaptureDevice.default(for: .video) else {
                DispatchQueue.main.async { self.showCaptureFailurePopup() }
                return
            }

            do {
                let input = try AVCaptureDeviceInput(device: captureDevice)
                self.captureSession.beginConfiguration()
                self.captureSession.inputs.forEach { self.captureSession.removeInput($0) }
                self.captureSession.outputs.forEach { self.captureSession.removeOutput($0) }

                if self.captureSession.canAddInput(input) {
                    self.captureSession.addInput(input)
                }
                if self.captureSession
                    .canAddOutput(self.captureOutput) {
                    self.captureSession.addOutput(self.captureOutput)
                }
                self.captureSession.commitConfiguration()

                DispatchQueue.main.async {
                    self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
                    self.previewLayer?.videoGravity = .resizeAspectFill
                    self.previewLayer?.frame = self.cameraView.bounds
                    self.cameraView.layer.insertSublayer(self.previewLayer!, at: 0)

                    if !self.captureSession.isRunning {
                        self.captureSession.startRunning()
                    }
                }
            } catch {
                DispatchQueue.main.async { self.showCaptureFailurePopup() }
            }
        }
    }

    private func showCaptureFailurePopup() {
        let alert = UIAlertController(
            title: "❌ 촬영에 실패하였습니다.",
            message: "책 제목이 명확하게 보이도록 다시 촬영해주세요.",
            preferredStyle: .alert
        )
        let retryAction = UIAlertAction(title: "다시 촬영하기", style: .default) { _ in
            self.setupCamera()
        }
        alert.addAction(retryAction)
        present(alert, animated: true)
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
