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
    private let cameraPermissionCancelRelay = PublishRelay<Void>()
    private let viewModel: AddBookViewModel

    // MARK: - UI Components

    private let navigationBar = CustomNavigationBar()

    private let titleLabel = Headline3Label(weight: .extraBold).then {
        $0.text = "새로운 책 추가하기"
        $0.adjustsFontSizeToFitWidth = true
        $0.minimumScaleFactor = 0.5
    }

    private let cameraContainerView = UIView().then {
        $0.backgroundColor = .black
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 20
    }

    private let infoLabel = BodyLabel().then {
        $0.text = "책의 정보를 파악할 수 있는 겉면 사진을 찍어주세요."
        $0.textAlignment = .center
        $0.numberOfLines = 2
    }

    private let loadingCircle = LoadingCircleView(frame: .zero).then {
        $0.isHidden = true
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
        setupAdaptiveLayout()
        setupCameraNotifications()

        checkCameraPermission { [weak self] granted in
            guard let self else {
                return
            }

            DispatchQueue.main.async {
                if granted {
                    self.setupCamera()
                } else {
                    self.showPermissionAlert()
                }
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updatePreviewLayerFrame()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession.stopRunning()
    }

    // MARK: - Overridden Functions

    // MARK: - UI Setup

    override func configureHierarchy() {
        for item in [
            navigationBar,
            titleLabel,
            cameraContainerView,
            infoLabel,
            captureButton,
            loadingCircle,
        ] {
            view.addSubview(item)
        }
        cameraContainerView.addSubview(cameraView)
    }

    override func configureLayout() {
        navigationBar.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(44)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(navigationBar.snp.bottom).offset(32)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        cameraContainerView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(32)
            $0.centerX.equalToSuperview()

            if UIDevice.current.userInterfaceIdiom == .pad {
                $0.width.equalToSuperview().multipliedBy(0.6)
                $0.height.equalTo(cameraContainerView.snp.width).multipliedBy(1.4)
            } else {
                $0.width.equalToSuperview().multipliedBy(0.9)
                $0.height.equalTo(cameraContainerView.snp.width).multipliedBy(1.2)
            }
        }

        cameraView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        infoLabel.snp.makeConstraints {
            $0.top.equalTo(cameraContainerView.snp.bottom).offset(32)
            $0.leading.trailing.equalToSuperview().inset(40)
        }

        captureButton.snp.makeConstraints {
            $0.top.equalTo(infoLabel.snp.bottom).offset(32)
            $0.centerX.equalToSuperview()
            $0.size.equalTo(60)

            // 아이패드에서 버튼이 짤리지 않도록 최소 여백 추가
            if UIDevice.current.userInterfaceIdiom == .pad {
                $0.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide.snp.bottom).offset(-40)
            }
        }

        loadingCircle.snp.makeConstraints {
            $0.center.equalTo(captureButton)
            $0.size.equalTo(80)
        }
    }

    // MARK: - ViewModel Binding

    override func bind() {
        let input = AddBookViewModel.Input(
            leftBarButtonTapTrigger: navigationBar.backButtonTapped.asObservable(),
            cameraPermissionCancelButtonTapTrigger: cameraPermissionCancelRelay.asObservable(),
            capturedImage: capturedImageRelay.asObservable()
        )

        let output = viewModel.transform(input)

        output.error
            .observe(on: MainScheduler.instance)
            .subscribe(with: self, onNext: { owner, error in
                owner.hideLoadingImage()
                ErrorAlertController(presentableError: error).present(from: owner)
            })
            .disposed(by: disposeBag)

        bindUI()
    }

    // MARK: - Functions

    // MARK: - Layout Configuration

    private func setupAdaptiveLayout() {
        if UIDevice.current.userInterfaceIdiom == .pad {
            titleLabel.font = UIFont.systemFont(ofSize: 32, weight: .bold)
            infoLabel.font = UIFont.systemFont(ofSize: 20)
            cameraContainerView.layer.cornerRadius = 40
        } else {
            cameraContainerView.layer.cornerRadius = 20
        }
    }

    // MARK: - Camera Handling

    /// 📌 앱이 활성화될 때 카메라 권한 체크
    private func setupCameraNotifications() {
        NotificationCenter.default.rx.notification(UIApplication.didBecomeActiveNotification)
            .subscribe(onNext: { [weak self] _ in
                self?.checkCameraPermission { [weak self] granted in
                    guard let self else {
                        return
                    }

                    DispatchQueue.main.async {
                        if granted {
                            self.setupCamera()
                        } else {
                            self.showPermissionAlert()
                        }
                    }
                }
            }).disposed(by: disposeBag)
    }

    /// 📌 카메라 권한 확인 함수 (클로저 추가)
    private func checkCameraPermission(completion: @escaping (Bool) -> Void) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)

        switch status {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        default:
            completion(false)
        }
    }

    private func setupCamera() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else {
                return
            }

            captureSession.beginConfiguration()
            defer { self.captureSession.commitConfiguration() }

            guard let device = AVCaptureDevice.default(for: .video),
                  let input = try? AVCaptureDeviceInput(device: device),
                  captureSession.canAddInput(input),
                  captureSession.canAddOutput(self.captureOutput) else {
                return
            }

            captureSession.addInput(input)
            captureSession.addOutput(captureOutput)

            DispatchQueue.main.async {
                self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
                self.previewLayer?.videoGravity = .resizeAspectFill
                self.previewLayer?.connection?.videoOrientation = .portrait
                self.cameraView.layer.addSublayer(self.previewLayer!)
                self.updatePreviewLayerFrame()

                DispatchQueue.global(qos: .userInitiated).async {
                    if !self.captureSession.isRunning {
                        self.captureSession.startRunning()
                    }
                }
            }
        }
    }

    private func updatePreviewLayerFrame() {
        DispatchQueue.main.async {
            self.previewLayer?.frame = self.cameraContainerView.bounds
            let cornerRadius = self.cameraContainerView.layer.cornerRadius
            self.previewLayer?.cornerRadius = cornerRadius
            self.cameraView.layer.cornerRadius = cornerRadius
        }
    }

    private func bindUI() {
        captureButton.rx.tap
            .bind { [weak self] in
                self?.showLoadingImage()
                self?.capturePhoto()
            }
            .disposed(by: disposeBag)
    }

    private func appDidBecomeActive() {
        checkCameraPermission { [weak self] granted in
            guard let self else {
                return
            }

            DispatchQueue.main.async {
                if granted {
                    self.setupCamera()
                } else {
                    self.showPermissionAlert()
                }
            }
        }
    }

    private func showLoadingImage() {
        captureButton.isHidden = true
        loadingCircle.isHidden = false
        loadingCircle.play()
    }

    private func hideLoadingImage() {
        loadingCircle.isHidden = true
        captureButton.isHidden = false
        loadingCircle.stop()
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

        let cancelAction = UIAlertAction(title: "취소", style: .cancel) { [weak self] _ in
            self?.cameraPermissionCancelRelay.accept(())
        }

        alert.addAction(settingsAction)
        alert.addAction(cancelAction)

        if UIDevice.current.userInterfaceIdiom == .pad {
            alert.popoverPresentationController?.sourceView = view
            alert.popoverPresentationController?.sourceRect = CGRect(
                x: view.bounds.midX,
                y: view.bounds.midY,
                width: 0,
                height: 0
            )
            alert.popoverPresentationController?.permittedArrowDirections = []
        }

        DispatchQueue.main.async {
            self.present(alert, animated: true)
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

        if UIDevice.current.userInterfaceIdiom == .pad {
            alert.popoverPresentationController?.sourceView = view
            alert.popoverPresentationController?.sourceRect = CGRect(
                x: view.bounds.midX,
                y: view.bounds.midY,
                width: 0,
                height: 0
            )
            alert.popoverPresentationController?.permittedArrowDirections = []
        }

        DispatchQueue.main.async {
            self.present(alert, animated: true)
        }
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
        capturedImageRelay.accept(image)
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
