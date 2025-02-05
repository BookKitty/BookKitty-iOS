// AddBookViewController.swift

import DesignSystem
import RxCocoa
import RxSwift
import SnapKit
import Then
import UIKit

final class AddBookViewController: BaseCameraViewController {
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

    /// ✅ `disposeBag`을 `BaseCameraViewController`에서 가져옴
    override var disposeBag: DisposeBag {
        super.disposeBag
    }

    private(set) lazy var manualAddButton = TextButton(title: "+ 책 추가하기")
    private(set) lazy var confirmButton = RoundButton(title: "추가 완료")

    /// ✅ `captureButton`은 `BaseCameraViewController`에 정의되어 있으므로, 기존 버튼 스타일을 수정하여 사용
    override func viewDidLoad() {
        super.viewDidLoad()
        captureButton.backgroundColor = .black
        captureButton.layer.cornerRadius = 36
        captureButton.layer.masksToBounds = true
    }

    // MARK: - DisposeBag 리셋 추가

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        resetDisposeBag() // ✅ 메모리 해제 방지를 위한 disposeBag 초기화
    }

    // MARK: Private

    private let viewModel: AddBookViewModel
    private let manualTitleRelay = PublishRelay<String>()

    private let backButton = UIButton().then {
        $0.setTitle("← 돌아가기", for: .normal)
        $0.setTitleColor(.systemTeal, for: .normal)
    }

    /// ✅ `새로운 책 추가하기` 볼드체 적용
    private let titleLabel = UILabel().then {
        $0.text = "새로운 책 추가하기"
        $0.font = UIFont.boldSystemFont(ofSize: 24)
        $0.textColor = .black
        $0.textAlignment = .center
    }

    /// ✅ 카메라 화면 `402x402` 크기 적용
    private let cameraContainerView = UIView().then {
        $0.backgroundColor = .black
        $0.layer.cornerRadius = 10
    }

    /// ✅ `노란 안내 박스(투명)` 크기 402x85 적용
    private let yellowInfoView = UIView().then {
        $0.backgroundColor = UIColor.systemYellow.withAlphaComponent(0.4)
        $0.layer.cornerRadius = 10
    }

    /// ✅ `BodyLabel` 적용 (안내 문구)
    private let infoLabel = BodyLabel().then {
        $0.text = "책의 정보를 파악할 수 있는 책 한권의 겉면\n혹은 여러 권의 책이 꽂혀 있는 책장의 사진을 찍어주세요."
        $0.textAlignment = .center
        $0.numberOfLines = 2
    }

    private lazy var bookCollectionView: UICollectionView = {
        let layout = UICollectionViewCompositionalLayout { _, layoutEnvironment in
            var config = UICollectionLayoutListConfiguration(appearance: .plain)
            config.backgroundColor = .clear
            return NSCollectionLayoutSection.list(
                using: config,
                layoutEnvironment: layoutEnvironment
            )
        }
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.register(BookCell.self, forCellWithReuseIdentifier: BookCell.identifier)
        return collectionView
    }()

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = .white
        navigationController?.navigationBar.isHidden = false // ✅ 네비게이션 바 표시

        view.addSubview(backButton)
        view.addSubview(titleLabel)
        view.addSubview(cameraContainerView)
        cameraContainerView.addSubview(cameraView)
        view.addSubview(yellowInfoView)
        yellowInfoView.addSubview(infoLabel)
        view.addSubview(captureButton)
        view.addSubview(manualAddButton)
        view.addSubview(confirmButton)
        view.addSubview(bookCollectionView)
    }

    private func setupConstraints() {
        backButton.snp.makeConstraints {
            $0.top.leading.equalTo(view.safeAreaLayoutGuide).inset(16)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(backButton.snp.bottom).offset(10)
            $0.centerX.equalToSuperview()
        }

        cameraContainerView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(20)
            $0.centerX.equalToSuperview()
            $0.width.height.equalTo(402)
        }

        cameraView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        yellowInfoView.snp.makeConstraints {
            $0.top.equalTo(cameraContainerView.snp.bottom).offset(10)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(402)
            $0.height.equalTo(85)
        }

        infoLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(10)
        }

        // ✅ `72x72 원형 카메라 버튼`
        captureButton.snp.makeConstraints {
            $0.top.equalTo(yellowInfoView.snp.bottom).offset(20)
            $0.centerX.equalToSuperview()
            $0.width.height.equalTo(72)
        }

        manualAddButton.snp.makeConstraints {
            $0.top.equalTo(captureButton.snp.bottom).offset(20)
            $0.centerX.equalToSuperview()
        }

        bookCollectionView.snp.makeConstraints {
            $0.top.equalTo(manualAddButton.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalTo(confirmButton.snp.top).offset(-20)
        }

        confirmButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            $0.height.equalTo(50)
        }
    }

    // MARK: - ViewModel Binding

    private func bindViewModel() {
        let input = AddBookViewModel.Input(
            captureButtonTapped: captureButton.rx.tap.asObservable(),
            manualAddButtonTapped: manualTitleRelay.asObservable(),
            confirmButtonTapped: confirmButton.rx.tap.asObservable()
        )

        let output = viewModel.transform(input)

        output.navigateToReviewAddBook
            .compactMap(\.first)
            .filter { !$0.title.isEmpty }
            .subscribe(onNext: { [weak self] book in
                self?.showReviewAddBookScene(bookList: [book])
            })
            .disposed(by: disposeBag)

        output.showTitleInputPopup
            .subscribe(onNext: { [weak self] in
                self?.showManualTitleInput()
            })
            .disposed(by: disposeBag)
    }

    private func showReviewAddBookScene(bookList _: [Book]) { /* 구현 */ }
    private func showManualTitleInput() { /* 구현 */ }
}
