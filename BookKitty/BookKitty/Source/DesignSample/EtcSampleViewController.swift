//
//  EtcSampleViewController.swift
//  BookKitty
//
//  Created by 임성수 on 2/4/25.
//

import DesignSystem
import SnapKit
import Then
import UIKit

class EtcSampleViewController: BaseViewController {
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupProperties()
        setupLayouts()
    }

    // MARK: - Internal

    let scrollView = UIScrollView()
    let contentView = UIView()

    let questionInput = QuestionInput(text: """
    adskfj asdf adfawef sadadfdkfj asdkjk
    이것은 여러줄
    여러줄을 한다
    """)

    let questionView = UserQuestionView(questionText: """
    adskfj asdf adfawef sadadfdkfj asdkjk 랄랄라 랄랄라 랄라 라라라라라라
    여러줄을 적용해보기
    스크롤 테스트1
    스크롤 테스트2
    스크롤 테스트3
    스크롤 테스트4

    빈줄도 넣고 테스트
        빈줄도 넣고 테스트3
    """)
}

// MARK: - UI Configure

extension EtcSampleViewController {
    private func setupViews() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        [
            questionInput,
            questionView,
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

        questionView.snp.makeConstraints { make in
            make.top.equalTo(questionInput.snp.bottom).offset(Vars.spacing48)
            make.leading.trailing.equalToSuperview().inset(Vars.paddingReg)
            make.bottom.equalToSuperview().inset(Vars.spacing48)
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    EtcSampleViewController()
}
