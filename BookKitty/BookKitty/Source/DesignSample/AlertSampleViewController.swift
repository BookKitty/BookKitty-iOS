//
//  AlertSampleViewController.swift
//  BookKitty
//
//  Created by 임성수 on 2/4/25.
//

import DesignSystem
import SnapKit
import Then
import UIKit

class AlertSampleViewController: BaseViewController {
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupProperties()
        setupLayouts()
    }

    // MARK: - Internal

    let failAlert1 = FailAlertPopupView()
    let failAlert2 = FailAlertPopupView(
        primaryMessage: "주요 메시지",
        secondaryMessage: "보조 메시지. 설명을 추가할 수 있습니다.",
        buttonTitle: "버튼 글자도 자유롭게"
    )
    let addBookView = ManageBookPopupView(mode: .add)
    let deleteBookView = ManageBookPopupView(bookTitle: "책 제목 변경 가능", mode: .delete)
    let bookTitleInputView = TitleInputPopupView()

    let scrollView = UIScrollView()
    let contentView = UIView()
}

// MARK: - UI Configure

extension AlertSampleViewController {
    private func setupViews() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        [
            failAlert1,
            failAlert2,
            addBookView,
            deleteBookView,
            bookTitleInputView,
        ].forEach { contentView.addSubview($0) }
    }

    private func setupProperties() {
        view.backgroundColor = Colors.brandMain
    }

    private func setupLayouts() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }

        failAlert1.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(Vars.spacing72)
            make.leading.trailing.equalToSuperview().inset(Vars.paddingReg)
        }

        failAlert2.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Vars.paddingReg)
            make.top.equalTo(failAlert1.snp.bottom).offset(Vars.spacing20)
        }

        addBookView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Vars.paddingReg)
            make.top.equalTo(failAlert2.snp.bottom).offset(Vars.spacing20)
        }

        deleteBookView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Vars.paddingReg)
            make.top.equalTo(addBookView.snp.bottom).offset(Vars.spacing20)
        }

        bookTitleInputView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Vars.paddingReg)
            make.top.equalTo(deleteBookView.snp.bottom).offset(Vars.spacing20)
            make.bottom.equalToSuperview().inset(Vars.spacing48)
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    AlertSampleViewController()
}
