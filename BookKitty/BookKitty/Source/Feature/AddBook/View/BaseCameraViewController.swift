import AVFoundation
import CoreML
import DesignSystem
import RxCocoa
import RxSwift
import SnapKit
import Then
import UIKit
import Vision

class BaseCameraViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    // MARK: - Properties

    open var captureButton: UIButton = CircleIconButton(iconId: "camera.fill")

    var captureSession = AVCaptureSession()
    var previewLayer: AVCaptureVideoPreviewLayer?
    var captureOutput = AVCapturePhotoOutput()
    private(set) var disposeBag = DisposeBag()

    let cameraView = UIView().then {
        $0.backgroundColor = .black
        $0.layer.cornerRadius = 8
        $0.clipsToBounds = true
    }

    var ocrTextHandler: ((String) -> Void)? // OCR 결과 전달용 클로저

    // MARK: - Lifecycle

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
        detectBookElements(in: image) // OCR 및 객체 감지 실행
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

    private func setupUI() {
        view.backgroundColor = .white
        view.addSubview(cameraView)
        view.addSubview(captureButton)
    }

    private func setupConstraints() {
        cameraView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.height.equalTo(402)
        }

        captureButton.snp.makeConstraints {
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            $0.centerX.equalToSuperview()
            $0.width.height.equalTo(72)
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
                print("🚨 카메라 초기화 실패")
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

    private func detectBookElements(in image: UIImage) {
        // CoreML 모델이 업데이트 가능한지 확인
        if let mlModel = MyObjectDetector5_1().model as? MLModel,
           mlModel.modelDescription.isUpdatable {
            print("✅ 이 모델은 업데이트 가능합니다.")
        } else {
            print("⚠️ 이 모델은 업데이트가 불가능합니다.")
        }

        // CoreML 모델 로드
        guard let model = try? VNCoreMLModel(for: MyObjectDetector5_1().model) else {
            print("⚠️ CoreML 모델 로드 실패: 모델이 업데이트 가능한지 확인 필요")
            return
        }

        let request = VNCoreMLRequest(model: model) { request, _ in
            guard let results = request.results as? [VNRecognizedObjectObservation] else {
                return
            }

            var extractedTexts: [String] = []
            let dispatchGroup = DispatchGroup()

            for observation in results
                where observation.labels.first?.identifier == "titles-or-authors" {
                dispatchGroup.enter()
                self.performOCR(on: image) { recognizedText in
                    if !recognizedText.isEmpty {
                        extractedTexts.append(recognizedText)
                    }
                    dispatchGroup.leave()
                }
            }

            dispatchGroup.notify(queue: .main) {
                if let bestTitle = extractedTexts.first {
                    self.ocrTextHandler?(bestTitle)
                }
            }
        }

        request.usesCPUOnly = true
        request.preferBackgroundProcessing = true

        do {
            let handler = VNImageRequestHandler(cgImage: image.cgImage!, options: [:])
            try handler.perform([request])
        } catch let error as NSError {
            print("⚠️ Vision Request Error: \(error.localizedDescription)")
        }
    }

    private func performOCR(on image: UIImage, completion: @escaping (String) -> Void) {
        guard let cgImage = image.cgImage else {
            completion("")
            return
        }

        let request = VNRecognizeTextRequest { request, error in
            guard error == nil,
                  let observations = request.results as? [VNRecognizedTextObservation] else {
                completion("")
                return
            }

            let recognizedText = observations.compactMap { $0.topCandidates(1).first?.string }
                .joined(separator: " ")
            completion(recognizedText)
        }

        request.recognitionLevel = .accurate

        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try requestHandler.perform([request])
        } catch {
            print("OCR 오류 발생: \(error.localizedDescription)")
            completion("")
        }
    }
}
