//
//  ErrorAlertView.swift
//  BookKitty
//
//  Created by 전성규 on 2/20/25.
//

import DesignSystem
import RxCocoa
import RxSwift
import Then
import UIKit

final class ErrorAlertView: UIView {
    // MARK: - Properties

    let confirmButtonDidTap = PublishRelay<Void>()

    private let popup: FailAlertPopupView

    private let disposeBag = DisposeBag()

    // MARK: - Lifecycle

    init(presentableError: AlertPresentableError) {
        popup = FailAlertPopupView(
            primaryMessage: presentableError.title,
            secondaryMessage: presentableError.body,
            buttonTitle: presentableError.buttonTitle
        )
        super.init(frame: .zero)

        configureBackground()
        configureHierarchy()
        configureLayout()
        bindPopup()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Functions

    private func configureBackground() { backgroundColor = .clear }

    private func configureHierarchy() {
        addSubview(popup)
    }

    private func configureLayout() {
        popup.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.horizontalEdges.equalToSuperview().inset(Vars.spacing24)
        }
    }

    private func bindPopup() {
        popup.confirmButton.rx.tap
            .bind(to: confirmButtonDidTap)
            .disposed(by: disposeBag)
    }
}
