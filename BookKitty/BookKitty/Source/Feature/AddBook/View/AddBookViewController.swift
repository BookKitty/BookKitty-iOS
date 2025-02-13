import AVFoundation
import BookMatchKit
import DesignSystem
import RxCocoa
import RxSwift
import SnapKit
import Then
import UIKit

final class AddBookViewController: BaseCameraViewController {
    // MARK: - Properties

    // MARK: - UI Components

    fileprivate let titleLabel = Headline3Label(weight: .extraBold).then {
        $0.text = "새로운 책 추가하기"
    }

    fileprivate let cameraContainerView = UIView().then {
        $0.backgroundColor = .black
        $0.clipsToBounds = true
    }

    fileprivate let yellowInfoView = UIView().then {
        $0.backgroundColor = Colors.brandSub3
    }

    fileprivate let infoLabel = BodyLabel().then {
        $0.text = "책의 정보를 파악할 수 있는 책 한권의 겉면 혹은 여러 권의 책이 꽂혀 있는 책장의 사진을 찍어주세요."
        $0.textAlignment = .center
    }

    private let manualAddPopup = TitleInputPopupView()
    private let navigationBar = CustomNavigationBar()

    private let dimmingView = DimmingView()

    private let confirmButtonRelay = PublishRelay<String>()
    private let manualTitleRelay = PublishRelay<String>()

    private let viewModel: AddBookViewModel
    private var addedBookTitles = Set<String>()

    // MARK: - Lifecycle

    init(viewModel: AddBookViewModel, bookMatchKit: BookMatchKit) { // ✅ bookMatchKit 추가
        self.viewModel = viewModel
        super.init(bookMatchKit: bookMatchKit) // ✅ BookMatchKit 전달

        ocrTextHandler = { [weak self] recognizedText in
            self?.manualTitleRelay.accept(recognizedText)
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.async {
            self.previewLayer?.frame = self.cameraView.bounds
        }
    }

    // MARK: - Overridden Functions

    override func handleCapturedImage(_ image: UIImage) {
        viewModel.handleCapturedImage(from: image)
    }

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
        view.addSubview(dimmingView)
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

        dimmingView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    // MARK: - ViewModel Binding

    override func bind() {
        let input = AddBookViewModel.Input(
            captureButtonTapped: captureButton.rx.tap.asObservable(),
            // TODO: catgureButton 눌렀을 때 데이터 viewModel로 넘겨주세요.
            leftBarButtonTapTrigger: navigationBar.backButtonTapped.asObservable(),
            cameraPermissionCancelButtonTapTrigger: cameraPermissionCancelRelay.asObservable()
        )

        let output = viewModel.transform(input)

        output.error
            .withUnretained(self)
            .subscribe(onNext: { error in
                print("Error occurred : \(error)")
            })
            .disposed(by: disposeBag)
    }
}

@available(iOS 17.0, *)
#Preview {
    let bookMatchKit = BookMatchKit(
        naverClientId: "dummyClientId",
        naverClientSecret: "dummyClientSecret"
    ) // ✅ BookMatchKit 인스턴스 생성
    return AddBookViewController(
        viewModel: AddBookViewModel(),
        bookMatchKit: bookMatchKit
    ) // ✅ 올바른 인스턴스 전달
}
