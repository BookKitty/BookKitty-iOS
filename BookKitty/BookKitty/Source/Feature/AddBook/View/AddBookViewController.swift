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

    private let cameraContainerView = UIView().then {
        $0.backgroundColor = .black
        $0.clipsToBounds = true
    }

    private let infoButtonContainerView = UIView().then {
        $0.backgroundColor = Colors.shadow25
    }

    private let infoLabel = BodyLabel().then {
        $0.text = "책의 정보를 파악할 수 있는 겉면 사진을 찍어주세요."
        $0.textColor = Colors.fontWhite
        $0.textAlignment = .center
    }

    private let loadingCircle = LoadingCircleView(frame: .zero).then {
        $0.isHidden = true
    }

    private var captureButton: UIButton = CircleIconButton(iconId: "camera.fill")

    // MARK: - ViewModel Binding

    private let confirmButtonTappedRelay = PublishRelay<Book>()

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

        NotificationCenter.default.rx.notification(UIApplication.didBecomeActiveNotification)
            .subscribe(onNext: { [weak self] _ in
                self?.appDidBecomActive()
            }).disposed(by: disposeBag)

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
        previewLayer?.frame = cameraView.bounds // 프레임 동기화
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !captureSession.isRunning {
            captureSession.startRunning() // 세션 재시작
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if captureSession.isRunning {
            captureSession.stopRunning() // 세션 정지
        }
    }

    // MARK: - Overridden Functions

    // MARK: - UI Setup

    override func configureNavItem() {
        navigationBar.setupTitle(with: "책 추가하기")
        navigationBar.setupRightBarButton(with: .input)
    }

    override func configureHierarchy() {
        [
            navigationBar,
            cameraContainerView,
            infoButtonContainerView,
            infoLabel,
            captureButton,
            loadingCircle,
        ].forEach { view.addSubview($0) }

        cameraContainerView.addSubview(cameraView)
    }

    override func configureLayout() {
        navigationBar.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.horizontalEdges.equalToSuperview()
            $0.height.equalTo(Vars.viewSizeReg)
        }

        cameraContainerView.snp.makeConstraints {
            $0.top.equalTo(navigationBar.snp.bottom)
            $0.horizontalEdges.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        cameraView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        infoButtonContainerView.snp.makeConstraints {
            $0.top.equalTo(infoLabel.snp.top).offset(-Vars.spacing8)
            $0.horizontalEdges.equalTo(view.safeAreaLayoutGuide)
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        infoLabel.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview().inset(Vars.spacing24)
            $0.bottom.equalTo(captureButton.snp.top).offset(-Vars.spacing24)
        }

        captureButton.snp.makeConstraints {
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(Vars.spacing32)
            $0.centerX.equalToSuperview()
            $0.width.height.equalTo(Vars.viewSizeLarge)
        }

        loadingCircle.snp.makeConstraints {
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(Vars.spacing32)
            $0.centerX.equalToSuperview()
        }
    }

    override func bind() {
        let input = AddBookViewModel.Input(
            cameraPermissionCancelButtonTapTrigger: cameraPermissionCancelRelay.asObservable(),
            leftBarButtonTapTrigger: navigationBar.backButtonTapped.asObservable(),
            addBookByTextButtonTapTrigger: navigationBar.rightButtonTapped.asObservable(),
            confirmButtonTapTrigger: confirmButtonTappedRelay.asObservable(),
            capturedImage: capturedImageRelay.asObservable() // ✅ OCR 바인딩 추가
        )

        let output = viewModel.transform(input)

        output.bookMatchSuccess
            .observe(on: MainScheduler.instance)
            .subscribe(with: self, onNext: { owner, book in
                let vc = AddBookConfirmViewController { [weak self] shouldAdd in
                    if shouldAdd {
                        self?.confirmButtonTappedRelay.accept(book)
                    } else {
                        self?.hideLoadingImage()
                    }
                }
                vc.present(by: owner, with: book)
            })
            .disposed(by: disposeBag)

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

    private func bindUI() {
        captureButton.rx.tap
            .bind { [weak self] in
                self?.showLoadingImage()
                self?.capturePhoto()
            }
            .disposed(by: disposeBag)
    }

    private func appDidBecomActive() {
        checkCameraPermission { granted in
            if granted {
                self.setupCamera()
            } else {
                self.showPermissionAlert()
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

        let cancelAction = UIAlertAction(title: "취소", style: .cancel) { [weak self] _ in
            self?.cameraPermissionCancelRelay.accept(())
        }

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

            // 기존 세션 정리
            if captureSession.isRunning {
                captureSession.stopRunning()
            }
            captureSession.beginConfiguration()
            captureSession.sessionPreset = .photo

            guard let captureDevice = AVCaptureDevice.default(for: .video) else {
                print("🚨 카메라 장치를 찾을 수 없음")
                return
            }

            do {
                let input = try AVCaptureDeviceInput(device: captureDevice)
                captureSession.inputs.forEach { self.captureSession.removeInput($0) }
                captureSession.addInput(input)

                captureSession.outputs.forEach { self.captureSession.removeOutput($0) }
                captureSession.addOutput(captureOutput)

                captureSession.commitConfiguration()

                DispatchQueue.main.async {
                    if self.previewLayer == nil {
                        self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
                        self.previewLayer?.videoGravity = .resizeAspectFill
                        self.previewLayer?.frame = self.cameraView.bounds
                        self.cameraView.layer.insertSublayer(self.previewLayer!, at: 0)
                    }

                    // 메인 스레드에서 세션 시작
                    if !self.captureSession.isRunning {
                        self.captureSession.startRunning()
                    }
                }
            } catch {
                BookKittyLogger.error("🚨 카메라 초기화 실패: \(error.localizedDescription)")
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
