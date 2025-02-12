import AVFoundation
import DesignSystem
import RxCocoa
import RxSwift
import SnapKit
import Then
import UIKit

final class AddBookViewController: BaseCameraViewController {
    // MARK: - Properties

    // MARK: - UI Components

    fileprivate let titleLabel = UILabel().then {
        $0.text = "새로운 책 추가하기"
        $0.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        $0.textAlignment = .center
    }

    fileprivate let cameraContainerView = UIView().then {
        $0.backgroundColor = .black
        $0.layer.cornerRadius = 10
        $0.clipsToBounds = true
    }

    fileprivate let yellowInfoView = UIView().then {
        $0.backgroundColor = UIColor.systemYellow.withAlphaComponent(0.4)
        $0.layer.cornerRadius = 10
    }

    fileprivate let infoLabel = UILabel().then {
        $0.text = "책의 정보를 파악할 수 있는 책 한 권의 겉면\n혹은 여러 권의 책이 꽂혀 있는 책장의 사진을 찍어주세요."
        $0.textAlignment = .center
        $0.numberOfLines = 2
        $0.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        $0.textColor = .black
    }

    private let manualAddPopup = TitleInputPopupView()
    private let navigationBar = CustomNavigationBar()
    private let dimmingView = DimmingView()

    private let confirmButtonRelay = PublishRelay<Void>()
    private let manualTitleRelay = PublishRelay<String>()

    private let viewModel: AddBookViewModel
    private var addedBookTitles = Set<String>()

    // MARK: - Lifecycle

    init(viewModel: AddBookViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)

        ocrTextHandler = { [weak self] recognizedText in
            self?.manualTitleRelay.accept(recognizedText)
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()

        bindViewModel()
        bindNavigationBar()
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

    // MARK: - Functions

    // MARK: - UI Setup

    fileprivate func setupUI() {
        view.backgroundColor = .white

        view.addSubview(titleLabel)
        view.addSubview(cameraContainerView)
        cameraContainerView.addSubview(cameraView)
        view.addSubview(yellowInfoView)
        yellowInfoView.addSubview(infoLabel)
        view.addSubview(captureButton)
    }

    fileprivate func setupConstraints() {
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            $0.centerX.equalToSuperview()
        }

        cameraContainerView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(16)
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
            $0.height.equalTo(100)
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
    }

    // MARK: - ViewModel Binding

    private func bindViewModel() {
        let input = AddBookViewModel.Input(
            captureButtonTapped: captureButton.rx.tap.asObservable(),
            leftBarButtonTapTrigger: navigationBar.backButtonTapped.asObservable(),
            popupViewConfirmButtonTapTrigger: confirmButtonRelay.asObservable()
        )

        let output = viewModel.transform(input)

        output.error
            .withUnretained(self)
            .subscribe(onNext: { error in
                print("Error occurred : \(error)")
            })
            .disposed(by: disposeBag)
    }

    private func bindNavigationBar() {
        navigationBar.rightButtonTapped
            .observe(on: MainScheduler.instance)
            .withUnretained(self)
            .bind(onNext: { owner, _ in
                let manualAddPopup = owner.manualAddPopup
                owner.dimmingView.isVisible.accept(true)

                if owner.view.subviews.contains(where: { $0 is TitleInputPopupView }) {
                    manualAddPopup.isHidden = false
                } else {
                    owner.view.addSubview(manualAddPopup)
                    manualAddPopup.snp.makeConstraints {
                        $0.horizontalEdges.equalToSuperview().inset(Vars.paddingReg)
                        $0.centerY.equalToSuperview()
                    }
                }
            }).disposed(by: disposeBag)

        manualAddPopup.confirmButton.rx.tap
            .bind(to: confirmButtonRelay)
            .disposed(by: disposeBag)

        manualAddPopup.cancelButton.rx.tap
            .map { false }
            .bind(to: dimmingView.isVisible)
            .disposed(by: disposeBag)

        dimmingView.isVisible
            .skip(1)
            .filter { !$0 }
            .observe(on: MainScheduler.instance)
            .withUnretained(self)
            .bind(onNext: { owner, _ in
                owner.manualAddPopup.isHidden = true
            }).disposed(by: disposeBag)
    }
}
