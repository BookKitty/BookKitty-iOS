//
//  BaseCameraViewController.swift
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

class BaseCameraViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    // MARK: Internal

    var captureSession = AVCaptureSession()
    var previewLayer: AVCaptureVideoPreviewLayer?
    var captureOutput = AVCapturePhotoOutput()

    /// ✅ `private(set) var`로 변경하여 하위 클래스에서 접근 가능하도록 수정
    private(set) var disposeBag = DisposeBag()

    // MARK: - UI Elements

    let cameraView = UIView().then {
        $0.backgroundColor = .black
        $0.layer.cornerRadius = 8
        $0.clipsToBounds = true
    }

    let captureButton = UIButton().then {
        let config = UIImage.SymbolConfiguration(pointSize: 36, weight: .bold)
        let cameraImage = UIImage(systemName: "camera.fill", withConfiguration: config)
        $0.setImage(cameraImage, for: .normal)
        $0.tintColor = .white
        $0.backgroundColor = .black
        $0.layer.cornerRadius = 36
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        checkCameraPermission { granted in
            if granted {
                self.setupCamera()
            } else {
                self.showPermissionAlert()
            }
        }
        setupUI()
        setupConstraints()
        configureViewModelBinding()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = cameraView.bounds
    }

    // MARK: - DisposeBag 리셋 메서드 추가 (필요시 사용 가능)

    func resetDisposeBag() {
        disposeBag = DisposeBag()
    }

    // MARK: - Capture Photo

    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        captureOutput.capturePhoto(with: settings, delegate: self)
    }

    func photoOutput(
        _: AVCapturePhotoOutput,
        didFinishProcessingPhoto _: AVCapturePhoto,
        error: Error?
    ) {
        guard error == nil else {
            showCaptureFailurePopup()
            return
        }
        print("📸 사진 촬영 성공")
    }

    // MARK: - ViewModel Binding

    func configureViewModelBinding() {
        // 하위 클래스에서 구현할 예정
    }

    // MARK: Private

    // MARK: - Camera Permission Check

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

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = .white
        view.addSubview(cameraView)
    }

    private func setupConstraints() {
        cameraView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.height.equalTo(300)
        }
    }

    // MARK: - Camera Setup

    private func setupCamera() {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let captureDevice = AVCaptureDevice.default(for: .video) else {
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
                if self.captureSession.canAddOutput(self.captureOutput) {
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
                print("🚨 카메라 초기화 실패")
            }
        }
    }

    // MARK: - 촬영 실패 팝업

    private func showCaptureFailurePopup() {
        let alert = UIAlertController(
            title: "촬영 실패",
            message: "책 제목이 명확하게 보이도록 다시 촬영해주세요.",
            preferredStyle: .alert
        )
        let retryAction = UIAlertAction(title: "다시 촬영하기", style: .default) { _ in
            self.capturePhoto()
        }
        alert.addAction(retryAction)
        present(alert, animated: true)
    }

    // MARK: - Camera Permission Alert

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
}
