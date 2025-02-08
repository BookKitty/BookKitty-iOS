//
//  LabelSample1ViewController.swift
//  BookKitty
//
//  Created by 임성수 on 2/3/25.
//

import DesignSystem
import SnapKit
import Then
import UIKit

final class LabelSample1ViewController: BaseViewController {
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupProperties()
        setupLayouts()
    }

    // MARK: - Internal

    let h3Label = Headline3Label().then {
        $0.text = "기본 Headline 3"
    }

    let semiBoldH3Label = Headline3Label(weight: .semiBold).then {
        $0.text = "SemiBold Headline 3, 색상 계층 1"
        $0.textColor = Colors.fontSub1
    }

    let extraBoldH3Label = Headline3Label(weight: .extraBold).then {
        $0.text = "ExtraBold Headline 3, 색상 계층 2"
        $0.textColor = Colors.fontSub2
    }

    let titleLabel = TitleLabel().then {
        $0.text = "기본 title"
    }

    let semiBoldTitleLabel = TitleLabel(weight: .semiBold).then {
        $0.text = "SemiBold title, 브랜드 서브 색상"
        $0.textColor = Colors.brandSub
    }

    let extraBoldTitleLabel = TitleLabel(weight: .extraBold).then {
        $0.text = "ExtraBold(app 기준 Heavy) title, 브랜드 메인 색상"
        $0.textColor = Colors.brandMain
    }
}

// MARK: - UI Configure

extension LabelSample1ViewController {
    func setupViews() {
        [
            h3Label,
            semiBoldH3Label,
            extraBoldH3Label,
            titleLabel,
            semiBoldTitleLabel,
            extraBoldTitleLabel,
        ].forEach { view.addSubview($0) }
    }

    func setupProperties() {}

    func setupLayouts() {
        h3Label.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Vars.paddingReg)
            make.top.equalToSuperview().inset(Vars.spacing72)
        }

        semiBoldH3Label.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Vars.paddingReg)
            make.top.equalTo(h3Label.snp.bottom).offset(Vars.spacing20)
        }

        extraBoldH3Label.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Vars.paddingReg)
            make.top.equalTo(semiBoldH3Label.snp.bottom).offset(Vars.spacing20)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Vars.paddingReg)
            make.top.equalTo(extraBoldH3Label.snp.bottom).offset(Vars.spacing20)
        }

        semiBoldTitleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Vars.paddingReg)
            make.top.equalTo(titleLabel.snp.bottom).offset(Vars.spacing20)
        }

        extraBoldTitleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Vars.paddingReg)
            make.top.equalTo(semiBoldTitleLabel.snp.bottom).offset(Vars.spacing20)
        }
    }
}
