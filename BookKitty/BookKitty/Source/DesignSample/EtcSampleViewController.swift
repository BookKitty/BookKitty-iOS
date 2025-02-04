//
//  EtcSampleViewController.swift
//  BookKitty
//
//  Created by MaxBook on 2/4/25.
//

import DesignSystem
import SnapKit
import Then
import UIKit

class EtcSampleViewController: BaseViewController {
    let scrollView = UIScrollView()
    let contentView = UIView()

    let questionInput = QuestionInput(text: """
    adskfj asdf adfawef sadadfdkfj asdkjk
    이것은 여러줄
    여러줄을 한다
    """)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupProperties()
        setupLayouts()
    }
}

// MARK: - UI Configure

extension EtcSampleViewController {
    private func setupViews() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        [
            questionInput,
        ].forEach { contentView.addSubview($0) }
    }

    private func setupProperties() {
        view.backgroundColor = Colors.background0
    }

    private func setupLayouts() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }

        questionInput.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(Vars.spacing72)
            make.leading.trailing.equalToSuperview().inset(Vars.paddingReg)
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    EtcSampleViewController()
}
