//
//  AddBookByTitlePopupViewController.swift
//  BookKitty
//
//  Created by 권승용 on 2/19/25.
//

import DesignSystem
import Kingfisher
import RxSwift
import SnapKit
import Then
import UIKit

final class AddBookByTitlePopupViewController: BaseViewController {
    // MARK: - Properties

    private let popup = AddBookByTitlePopupView()
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
                owned.completion(false)
                owned.dismiss(animated: false)
            })
            .disposed(by: disposeBag)

        popup.confirmButton.rx.tap
            .subscribe(with: self, onNext: { owned, _ in
                owned.completion(true)
                owned.dismiss(animated: false)
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
    AddBookByTitlePopupViewController { result in
        print(result)
    }
}
