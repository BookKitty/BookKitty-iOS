//
//  AddBookConfirmViewController.swift
//  BookKitty
//
//  Created by 권승용 on 2/19/25.
//

import DesignSystem
import RxSwift
import SnapKit
import Then
import UIKit

final class AddBookConfirmViewController: BaseViewController {
    // MARK: - Properties

    private let popup = AddBookConfirmView()
    private let completion: (Bool) -> Void

    // MARK: - Lifecycle

    init(_ completion: @escaping (Bool) -> Void) {
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Overridden Functions

    override func configureBackground() {
        view.backgroundColor = Colors.backgroundModal
    }

    override func configureHierarchy() {
        view.addSubview(popup)
    }

    override func configureLayout() {
        popup.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(Vars.spacing24)
            make.centerY.equalToSuperview()
        }
    }

    override func bind() {
        popup.cancelButton.rx.tap
            .subscribe(with: self, onNext: { owned, _ in
                owned.dismiss(animated: false)
                owned.completion(false)
            })
            .disposed(by: disposeBag)

        popup.confirmButton.rx.tap
            .subscribe(with: self, onNext: { owned, _ in
                owned.dismiss(animated: false)
                owned.completion(true)
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Functions

    func present(by parent: UIViewController, with book: Book) {
        modalPresentationStyle = .overFullScreen
        popup.configure(
            thumbnailUrl: book.thumbnailUrl,
            title: book.title
        )
        parent.present(self, animated: false)
    }
}

@available(iOS 17.0, *)
#Preview {
    AddBookConfirmViewController { _ in
    }
}
