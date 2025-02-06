//
//  AddBookViewController.swift
//  BookKitty
//
//  Created by 반성준 on 2/5/25.
//

import DesignSystem
import RxCocoa
import RxSwift
import SnapKit
import Then
import UIKit

final class AddBookViewController: BaseCameraViewController {
    // MARK: Lifecycle

    // MARK: - Init

    init(viewModel: AddBookViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
        setupConstraints()
        bindViewModel()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.async {
            self.previewLayer?.frame = self.cameraView.bounds
        }
    }

    // MARK: Private

    // MARK: - Private Properties

    private let viewModel: AddBookViewModel
    private let manualTitleRelay = PublishRelay<String>()
    private let confirmButtonRelay = PublishRelay<Void>()
    private var addedBookTitles = Set<String>()

    /// ✅ ReviewAddBookViewController 인스턴스 (재사용 목적)
    private var reviewViewController: ReviewAddBookViewController?

    /// ✅ "새로운 책 추가하기" 타이틀
    private let titleLabel = UILabel().then {
        $0.text = "새로운 책 추가하기"
        $0.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        $0.textAlignment = .center
    }

    /// ✅ 402x402 크기의 카메라 화면 컨테이너
    private let cameraContainerView = UIView().then {
        $0.backgroundColor = .black
        $0.layer.cornerRadius = 10
        $0.clipsToBounds = true
    }

    /// ✅ 카메라 아래 투명한 노란 박스
    private let yellowInfoView = UIView().then {
        $0.backgroundColor = UIColor.systemYellow.withAlphaComponent(0.4)
        $0.layer.cornerRadius = 10
    }

    /// ✅ 안내 문구 (노란 박스 안에 배치)
    private let infoLabel = UILabel().then {
        $0.text = "책의 정보를 파악할 수 있는 책 한 권의 겉면\n혹은 여러 권의 책이 꽂혀 있는 책장의 사진을 찍어주세요."
        $0.textAlignment = .center
        $0.numberOfLines = 2
        $0.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        $0.textColor = .black
    }

    // MARK: - 네비게이션 바 설정

    private func setupNavigationBar() {
        navigationController?.navigationBar.isHidden = false

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "돌아가기",
            style: .plain,
            target: self,
            action: #selector(didTapBackButton)
        )

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "제목 입력",
            style: .plain,
            target: self,
            action: #selector(didTapManualAddButton)
        )
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = .white

        view.addSubview(titleLabel)
        view.addSubview(cameraContainerView)
        cameraContainerView.addSubview(cameraView)
        view.addSubview(yellowInfoView)
        yellowInfoView.addSubview(infoLabel)
        view.addSubview(captureButton)
    }

    private func setupConstraints() {
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
            $0.top.equalTo(cameraContainerView.snp.bottom).offset(0)
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
            manualAddButtonTapped: manualTitleRelay.asObservable(),
            confirmButtonTapped: confirmButtonRelay.asObservable()
        )

        let output = viewModel.transform(input)

        output.navigateToReviewAddBook
            .compactMap(\.first)
            .filter { !$0.title.isEmpty }
            .subscribe(onNext: { [weak self] book in
                self?.navigateToReviewScene(with: book)
            })
            .disposed(by: disposeBag)

        output.showTitleInputPopup
            .subscribe(onNext: { [weak self] in
                self?.showManualTitleInput()
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Navigation

    private func navigateToReviewScene(with book: Book) {
        guard !addedBookTitles.contains(book.title) else {
            return
        }
        addedBookTitles.insert(book.title)

        if let reviewVC = reviewViewController {
            reviewVC.appendBook(book)
        } else {
            let reviewViewModel = ReviewAddBookViewModel(initialBookList: [book])
            let reviewVC = ReviewAddBookViewController(viewModel: reviewViewModel)
            reviewViewController = reviewVC
            navigationController?.pushViewController(reviewVC, animated: true)
        }
    }

    // MARK: - Show Manual Title Input

    private func showManualTitleInput() {
        let alert = UIAlertController(
            title: "책 제목 입력",
            message: "책 제목을 입력해주세요.",
            preferredStyle: .alert
        )
        alert.addTextField()

        let addAction = UIAlertAction(title: "추가", style: .default) { [weak self] _ in
            if let title = alert.textFields?.first?.text, !title.isEmpty {
                let book = Book(
                    isbn: "",
                    title: title,
                    author: "알 수 없음",
                    publisher: "알 수 없음",
                    thumbnailUrl: nil
                )
                self?.navigateToReviewScene(with: book)
            }
        }
        let cancelAction = UIAlertAction(title: "취소", style: .cancel)

        alert.addAction(addAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }

    @objc
    private func didTapBackButton() {
        navigationController?.popViewController(animated: true)
    }

    @objc
    private func didTapManualAddButton() {
        showManualTitleInput()
    }
}
