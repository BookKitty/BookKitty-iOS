//
//  ErrorAlertController.swift
//  BookKitty
//
//  Created by 권승용 on 2/13/25.
//

import DesignSystem
import RxCocoa
import RxSwift
import SnapKit
import Then
import UIKit

final class ErrorAlertController: BaseViewController {
    // MARK: - Properties

    let confirmButtonDidTap = PublishRelay<Void>()

    private let popup: FailAlertPopupView

    // MARK: - Lifecycle

    init(presentableError: AlertPresentableError) {
        popup = FailAlertPopupView(
            primaryMessage: presentableError.title,
            secondaryMessage: presentableError.body,
            buttonTitle: presentableError.buttonTitle
        )
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Overridden Functions

    override func configureHierarchy() {
        view.addSubview(popup)
    }

    override func configureLayout() {
        popup.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.horizontalEdges.equalToSuperview().inset(Vars.spacing24)
        }
    }

    override func configureBackground() {
        view.backgroundColor = Colors.backgroundModal
    }

    override func bind() {
        popup.confirmButton.rx.tap
            .do(onNext: { [weak self] _ in
                self?.confirmButtonDidTap.accept(())
            })
            .subscribe(onNext: { [weak self] in
                self?.dismiss(animated: false)
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Functions

    func present(from parentVC: UIViewController) {
        modalPresentationStyle = .overFullScreen
        parentVC.present(self, animated: false)
    }
}

@available(iOS 17.0, *)
#Preview {
    ErrorAlertController(presentableError: NetworkError.networkUnstable)
}
