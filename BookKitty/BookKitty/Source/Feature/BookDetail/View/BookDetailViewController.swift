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
    // MARK: - Properties

    // MARK: - Private

    private let viewModel: BookDetailViewModel

    private let popupViewConfirmButtonTapTrigger = PublishRelay<Void>()

    private let dimmingView = DimmingView()
    private let navigationBar = CustomNavigationBar()
    private let scrollView = UIScrollView().then { $0.alwaysBounceVertical = true }
    private let contentStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = Vars.spacing48
    }

    private let infoSection = BookDetailInfoSection()
    private let introSection = BookDetailIntroSection()
    private var popupView: ManageBookPopupView?

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

        bindNavigationBar()
    }

    // MARK: - Overridden Functions

    // MARK: - Internal

    override func bind() {
        let input = BookDetailViewModel.Input(
            viewDidLoad: viewDidLoadRelay.asObservable(),
            leftBarButtonTapTrigger: navigationBar.backButtonTapped.asObservable(),
            popupViewConfirmButtonTapTrigger: popupViewConfirmButtonTapTrigger.asObservable()
        )

        let output = viewModel.transform(input)

        output.bookDetail
            .withUnretained(self)
            .observe(on: MainScheduler.instance)
            .bind(onNext: { owner, bookDetail in
                owner.introSection.setupData(with: bookDetail.description)
                owner.infoSection.inforView.setupData(with: bookDetail)

                let mode: ManageBookMode = bookDetail.isOwned ? .delete : .add
                owner.popupView = ManageBookPopupView(bookTitle: bookDetail.title, mode: mode)

                if mode == .delete {
                    owner.navigationBar.setupRightBarButton(with: .delete)
                } else {
                    owner.navigationBar.setupRightBarButton(with: .add)
                }
            }).disposed(by: disposeBag)
    }

    override func configureHierarchy() {
        [navigationBar, scrollView, dimmingView].forEach { view.addSubview($0) }
        scrollView.addSubview(contentStackView)
        [infoSection, introSection].forEach { contentStackView.addArrangedSubview($0) }
    }

    override func configureLayout() {
        navigationBar.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.horizontalEdges.equalToSuperview()
            $0.height.equalTo(Vars.viewSizeReg)
        }

        scrollView.snp.makeConstraints {
            $0.top.equalTo(navigationBar.snp.bottom)
            $0.horizontalEdges.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        contentStackView.snp.makeConstraints {
            $0.edges.width.equalToSuperview().inset(Vars.paddingReg)
        }

        dimmingView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    // MARK: - Functions

    private func bindNavigationBar() {
        navigationBar.rightButtonTapped
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
    BookDetailViewController(
        viewModel: BookDetailViewModel(
            bookDetail: Book(
                isbn: "9788950963262",
                title: "침묵의 기술",
                author: "조제프 앙투안 투생 디누아르",
                publisher: "아르테(arte)",
                thumbnailUrl: URL(
                    string: "https://shopping-phinf.pstatic.net/main_3249696/32496966995.20240321071044.jpg"
                )
            ),
            bookRepository: MockBookRepository()
        )
    )
}
