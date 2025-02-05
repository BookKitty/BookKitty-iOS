//
//  BaseCameraViewController.swift
//  BookKitty
//
//  Created by 반성준 on 2/5/25.
//

import AVFoundation
import UIKit

class BaseCameraViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    var captureSession = AVCaptureSession()
    var previewLayer: AVCaptureVideoPreviewLayer?
    var captureOutput = AVCapturePhotoOutput()

    let cameraView = UIView().then {
        $0.backgroundColor = .black
        $0.layer.cornerRadius = 8
        $0.clipsToBounds = true
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
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = cameraView.bounds
    }

    func checkCameraPermission(completion: @escaping (Bool) -> Void) {
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

    func showPermissionAlert() {
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

    func setupCamera() {
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
                DispatchQueue.main.async { self.showCaptureFailurePopup() }
            }
        }
    }

    func showCaptureFailurePopup() {
        let alert = UIAlertController(
            title: "촬영 실패",
            message: "책 제목이 명확하게 보이도록 다시 촬영해주세요.",
            preferredStyle: .alert
        )
        let retryAction = UIAlertAction(title: "다시 촬영하기", style: .default) { _ in
            self.setupCamera()
        }
        alert.addAction(retryAction)
        present(alert, animated: true)
    }

    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        captureOutput.capturePhoto(with: settings, delegate: self)
    }
}
