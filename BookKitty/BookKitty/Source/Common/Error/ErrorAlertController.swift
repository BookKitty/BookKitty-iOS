//
//  ErrorAlertController.swift
//  BookKitty
//
//  Created by 권승용 on 2/13/25.
//

import DesignSystem
import RxSwift
import SnapKit
import Then
import UIKit

final class ErrorAlertController: BaseViewController {
    // MARK: - Properties

    private let popup: FailAlertPopupView

    // MARK: - Lifecycle

    init(
        errorTitle: String,
        errorBody: String,
        buttonTitle: String
    ) {
        popup = FailAlertPopupView(
            primaryMessage: errorTitle,
            secondaryMessage: errorBody,
            buttonTitle: buttonTitle
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
    ErrorAlertController(
        errorTitle: "some text",
        errorBody: "secondary message",
        buttonTitle: "button title"
    )
}
