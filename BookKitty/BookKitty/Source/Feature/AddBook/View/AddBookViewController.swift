import AVFoundation
import DesignSystem
import RxCocoa
import RxSwift
import SnapKit
import Then
import UIKit

final class AddBookViewController: BaseViewController {
    // MARK: - Properties

    private var captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var captureOutput = AVCapturePhotoOutput()
    private let cameraView = UIView().then { $0.backgroundColor = .black }

    private let capturedImageRelay = PublishRelay<UIImage>()
    private let viewModel: AddBookViewModel

    // MARK: - UI Components

    private let navigationBar = CustomNavigationBar()

    private let titleLabel = Headline3Label(weight: .extraBold).then {
        $0.text = "새로운 책 추가하기"
    }

    private let cameraContainerView = UIView().then {
        $0.backgroundColor = .black
        $0.clipsToBounds = true
    }

    private let yellowInfoView = UIView().then {
        $0.backgroundColor = Colors.brandSub3
    }

    private let infoLabel = BodyLabel().then {
        $0.text = "책의 정보를 파악할 수 있는 책 한권의 겉면 혹은 여러 권의 책이 꽂혀 있는 책장의 사진을 찍어주세요."
        $0.textAlignment = .center
    }

    private var captureButton: UIButton = CircleIconButton(iconId: "camera.fill")

    // MARK: - Lifecycle

    init(viewModel: AddBookViewModel) {
        self.viewModel = viewModel
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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.async {
            self.previewLayer?.frame = self.cameraView.bounds
        }
    }

    override func viewDidDisappear(_: Bool) {
        captureSession.stopRunning()
    }

    // MARK: - Overridden Functions

    // MARK: - UI Setup

    override func configureHierarchy() {
        super.configureHierarchy()
        view.backgroundColor = .white

        view.addSubview(navigationBar)
        view.addSubview(titleLabel)
        view.addSubview(cameraContainerView)
        cameraContainerView.addSubview(cameraView)
        view.addSubview(yellowInfoView)
        yellowInfoView.addSubview(infoLabel)
        view.addSubview(captureButton)
    }

    override func configureLayout() {
        super.configureLayout()

        navigationBar.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.horizontalEdges.equalToSuperview()
            $0.height.equalTo(Vars.viewSizeReg)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(navigationBar.snp.bottom).offset(Vars.spacing32)
            $0.centerX.equalToSuperview()
        }

        cameraContainerView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(Vars.spacing32)
            $0.centerX.equalToSuperview()
            $0.width.height.equalTo(402)
        }

        cameraView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        yellowInfoView.snp.makeConstraints {
            $0.top.equalTo(cameraContainerView.snp.bottom)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(402)
            $0.height.equalTo(85)
        }

        infoLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(Vars.paddingReg)
        }

        captureButton.snp.makeConstraints {
            $0.top.equalTo(yellowInfoView.snp.bottom).offset(Vars.spacing32)
            $0.centerX.equalToSuperview()
            $0.width.height.equalTo(Vars.viewSizeLarge)
        }
    }

    // MARK: - ViewModel Binding

    override func bind() {
        let input = AddBookViewModel.Input(
            leftBarButtonTapTrigger: navigationBar.backButtonTapped.asObservable(),
            capturedImage: capturedImageRelay.asObservable() // ✅ OCR 바인딩 추가
        )

        let output = viewModel.transform(input)

        output.error
            .subscribe(onNext: { error in
                print("⚠️ Error: \(error.localizedDescription)")
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Functions

    private func bindUI() {
        captureButton.rx.tap
            .bind { [weak self] in
                print("촬영 버튼 눌림")
                self?.capturePhoto()
            }
            .disposed(by: disposeBag)
    }
}

extension AddBookViewController: AVCapturePhotoCaptureDelegate {
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

        print("📸 이미지 캡처 성공")
        capturedImageRelay.accept(image) // ✅ OCR을 위한 이미지 전달
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
