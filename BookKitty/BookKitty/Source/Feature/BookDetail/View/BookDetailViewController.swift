//
//  BookDetailViewController.swift
//  BookKitty
//  P-006
//
//  Created by 전성규 on 1/27/25.
//

import DesignSystem
import RxCocoa
import RxSwift
import SnapKit
import UIKit

final class BookDetailViewController: BaseViewController {
    // MARK: - Lifecycle

    init(viewModel: BookDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        bindLeftBarButton()
        bindRightBarButton()
        bindPopupView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.navigationBar.isHidden = false
    }

    // MARK: - Internal

    override func bind() {
        let input = BookDetailViewModel.Input(
            viewDidLoad: viewDidLoadRelay.asObservable(),
            leftBarButtonTapTrigger: leftBarButtonTapTrigger.asObservable(),
            popupViewConfirmButtonTapTrigger: popupViewConfirmButtonTapTrigger.asObservable()
        )

        let output = viewModel.transform(input)

        output.model
            .withUnretained(self)
            .observe(on: MainScheduler.instance)
            .bind(onNext: { owner, model in
                owner.introSection.setupData(with: model.description)
                owner.infoSection.inforView.setupData(with: model)
                owner.configureRightBarButton(with: model.isOwned)

                let mode: ManageBookMode = model.isOwned ? .delete : .add
                owner.popupView = ManageBookPopupView(bookTitle: model.title, mode: mode)
            }).disposed(by: disposeBag)
    }

    override func configureHierarchy() {
        [scrollView, dimmingView].forEach { view.addSubview($0) }
        scrollView.addSubview(contentStackView)
        [infoSection, introSection].forEach { contentStackView.addArrangedSubview($0) }
    }

    override func configureLayout() {
        scrollView.snp.makeConstraints {
            $0.verticalEdges.equalTo(view.safeAreaLayoutGuide)
            $0.horizontalEdges.equalToSuperview()
        }

        contentStackView.snp.makeConstraints {
            $0.edges.width.equalToSuperview().inset(Vars.paddingReg)
        }

        dimmingView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    override func configureNavItem() {
        var config = UIButton.Configuration.plain()
        config.title = "돌아가기"
        config.image = UIImage(systemName: "chevron.left")
        config.imagePlacement = .leading
        config.imagePadding = 5
        config.contentInsets = .zero

        let backButton = UIButton(configuration: config)
        backButton.tintColor = Colors.brandSub

        let backBarButtonItem = UIBarButtonItem(customView: backButton)

        navigationItem.leftBarButtonItem = backBarButtonItem
    }

    // MARK: - Private

    private let viewModel: BookDetailViewModel
    private let leftBarButtonTapTrigger = PublishRelay<Void>()
    private let rightBarButtonTabTrigger = PublishRelay<Void>()
    private let popupViewConfirmButtonTapTrigger = PublishRelay<Void>()

    private let dimmingView = DimmingView()
    private let scrollView = UIScrollView().then { $0.alwaysBounceVertical = true }
    private let contentStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = Vars.spacing48
    }

    private let infoSection = BookDetailInfoSection()
    private let introSection = BookDetailIntroSection()
    private var popupView: ManageBookPopupView?

    private func configureRightBarButton(with isOwned: Bool) {
        if isOwned {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "삭제")
        } else {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "추가")
        }

        navigationItem.rightBarButtonItem?.tintColor = Colors.brandSub
    }

    private func bindRightBarButton() {
        guard let rightBarButton = navigationItem.rightBarButtonItem else {
            return
        }

        rightBarButton.rx.tap
            .bind(to: rightBarButtonTabTrigger)
            .disposed(by: disposeBag)
    }

    private func bindLeftBarButton() {
        guard let leftBarButton = navigationItem.leftBarButtonItem?.customView as? UIButton
        else {
            return
        }

        leftBarButton.rx.tap
            .bind(to: leftBarButtonTapTrigger)
            .disposed(by: disposeBag)
    }

    private func bindPopupView() {
        rightBarButtonTabTrigger
            .observe(on: MainScheduler.instance)
            .withUnretained(self)
            .bind(onNext: { owner, _ in
                guard let manageBookPopupView = owner.popupView else {
                    return
                }
                owner.dimmingView.isVisible.accept(true)

                if owner.view.subviews.contains(where: { $0 is ManageBookPopupView }) {
                    manageBookPopupView.isHidden = false
                } else {
                    owner.view.addSubview(manageBookPopupView)
                    manageBookPopupView.snp.makeConstraints {
                        $0.horizontalEdges.equalToSuperview().inset(Vars.paddingReg)
                        $0.centerY.equalToSuperview()
                    }
                }
            }).disposed(by: disposeBag)

        popupView?.confirmButton.rx.tap
            .bind(to: popupViewConfirmButtonTapTrigger)
            .disposed(by: disposeBag)

        popupView?.cancelButton.rx.tap
            .map { false }
            .bind(to: dimmingView.isVisible)
            .disposed(by: disposeBag)

        dimmingView.isVisible
            .skip(1)
            .filter { !$0 }
            .observe(on: MainScheduler.instance)
            .withUnretained(self)
            .bind(onNext: { owner, _ in
                owner.popupView?.isHidden = true
            }).disposed(by: disposeBag)
    }
}

@available(iOS 17.0, *)
#Preview {
    BookDetailViewController(viewModel: BookDetailViewModel())
}
