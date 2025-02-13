import AVFoundation
import BookMatchKit
import CoreML
import DesignSystem
import RxCocoa
import RxSwift
import SnapKit
import Then
import UIKit
import Vision

class BaseCameraViewController: BaseViewController, AVCapturePhotoCaptureDelegate {
    // MARK: - Properties

    open var captureButton: UIButton = CircleIconButton(iconId: "camera.fill")

    var captureSession = AVCaptureSession()
    var previewLayer: AVCaptureVideoPreviewLayer?
    var captureOutput = AVCapturePhotoOutput()

    let cameraView = UIView().then { $0.backgroundColor = .black }

    var ocrTextHandler: ((String) -> Void)? // OCR 결과 전달용 클로저

    private let bookMatchKit: BookMatchKit

    // MARK: - Lifecycle

    init(bookMatchKit: BookMatchKit) {
        self.bookMatchKit = bookMatchKit
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        bindUI()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        DispatchQueue.main.async {
            self.previewLayer?.frame = self.cameraView.bounds
        }
    }

    // MARK: - Functions

    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        captureOutput.capturePhoto(with: settings, delegate: self)
    }

    func photoOutput(
        _: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        guard error == nil, let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            showCaptureFailurePopup()
            return
        }
        handleCapturedImage(image)
    }

    func handleCapturedImage(_ image: UIImage) {
        // 이미지 전처리 (리사이즈 및 크롭)
        let resizedImage = image.resized(toWidth: 1024)
        bookMatchKit.extractText(from: resizedImage!)
            .subscribe(onSuccess: { [weak self] extractedTexts in
                if let bestTitle = extractedTexts.first {
                    print("✅ 최종 OCR 결과: \(bestTitle)")
                    self?.ocrTextHandler?(bestTitle)
                } else {
                    print("⚠️ OCR 결과 없음")
                }
            }, onFailure: { error in
                print("⚠️ OCR 실패: \(error.localizedDescription)")
            })
            .disposed(by: disposeBag)
    }

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
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }

        let cancelAction = UIAlertAction(title: "취소", style: .cancel)

        alert.addAction(settingsAction)
        alert.addAction(cancelAction)

        DispatchQueue.main.async {
            self.present(alert, animated: true)
        }
    }

    private func bindUI() {
        captureButton.rx.tap
            .bind { [weak self] in
                self?.capturePhoto()
            }
            .disposed(by: disposeBag)
    }

    private func setupCamera() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else {
                return
            }
            guard let captureDevice = AVCaptureDevice.default(for: .video) else {
                print("🚨 카메라 장치를 찾을 수 없음")
                return
            }
            do {
                let input = try AVCaptureDeviceInput(device: captureDevice)
                captureSession.beginConfiguration()
                if captureSession.canAddInput(input) {
                    captureSession.addInput(input)
                }
                if captureSession.canAddOutput(captureOutput) {
                    captureSession.addOutput(captureOutput)
                }
                captureSession.commitConfiguration()

                DispatchQueue.main.async {
                    self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
                    self.previewLayer?.videoGravity = .resizeAspectFill
                    self.previewLayer?.frame = self.cameraView.bounds
                    self.cameraView.layer.insertSublayer(self.previewLayer!, at: 0)

                    // 백그라운드에서 AVCaptureSession 시작
                    DispatchQueue.global(qos: .userInitiated).async {
                        if !self.captureSession.isRunning {
                            self.captureSession.startRunning()
                        }
                    }
                }
            } catch {
                print("🚨 카메라 초기화 실패: \(error.localizedDescription)")
            }
        }
    }

    private func showCaptureFailurePopup() {
        let alert = UIAlertController(
            title: "촬영 실패",
            message: "이미지를 캡처하는 데 실패했습니다. 다시 시도해주세요.",
            preferredStyle: .alert
        )

        let retryAction = UIAlertAction(title: "재시도", style: .default) { _ in
            self.capturePhoto()
        }

        let cancelAction = UIAlertAction(title: "취소", style: .cancel)

        alert.addAction(retryAction)
        alert.addAction(cancelAction)

        DispatchQueue.main.async {
            self.present(alert, animated: true)
        }
    }
}

// MARK: - UIImage Extension (리사이즈 기능 추가)

extension UIImage {
    func resized(toWidth width: CGFloat) -> UIImage? {
        let scaleFactor = width / size.width
        let canvasSize = CGSize(width: width, height: size.height * scaleFactor)

        UIGraphicsBeginImageContextWithOptions(canvasSize, false, UIScreen.main.scale)
        defer { UIGraphicsEndImageContext() }

        draw(in: CGRect(origin: .zero, size: canvasSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
