//
//  LabelSample2ViewController.swift
//  BookKitty
//
//  Created by MaxBook on 2/3/25.
//

import DesignSystem
import SnapKit
import Then
import UIKit

final class LabelSample2ViewController: BaseViewController {
    let bodyLabel = BodyLabel().then {
        $0.text = "기본 본문용 body label"
    }

    let longBodyLabel = BodyLabel().then {
        $0
            .text = """
            기본 본문용 body label. 긴 텍스트를 표현하는 경우의 샘플을 표시합니다. 
            샘플로 긴 텍스트를 작성하여 이를 확인하고 있습니다. 기본적으로 모든 Label은 numberOfLines 속성이 0 이므로 멀티라인을 지원하고 있습니다. 모든 Label은 높이값을 지정하고 있지 않으므로, 텍스트에 따라 자동으로 확장.
            """
    }

    let semiBoldbodyLabel = BodyLabel(weight: .semiBold).then {
        $0.text = "조금 두꺼운 body label, disabled color"
        $0.textColor = Colors.fontDisabled
    }

    let extraBoldBodyLabel = BodyLabel(weight: .extraBold).then {
        $0.text = "기본 본문에서 아주 두껍게 강조하는 body label"
    }

    let captionLabel = CaptionLabel().then {
        $0.textColor = Colors.fontSub1
        $0
            .text =
            "날짜나 보조텍스트 표시용 caption label. 기본적으로 fontMain 색상을 사용하나, 실제로 앱에서는 현재 색상처럼 fontSub1 색상을 더 많이 사용합니다."
    }

    let twoLineLabel = TwoLineLabel(text1: "첫번째 줄 텍스트", text2: "두번째 줄 텍스트. brandMain color")
    let tagLabel1 = OwnedTagLabel()
    let tagLabel2 = OwnedTagLabel(isOwned: false)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupProperties()
        setupLayouts()
    }
}

// MARK: - UI Configure

extension LabelSample2ViewController {
    func setupViews() {
        [
            bodyLabel,
            longBodyLabel,
            semiBoldbodyLabel,
            extraBoldBodyLabel,
            captionLabel,
            twoLineLabel,
            tagLabel1,
            tagLabel2,
        ].forEach { view.addSubview($0) }
    }

    func setupProperties() {}

    func setupLayouts() {
        bodyLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Vars.paddingReg)
            make.top.equalToSuperview().inset(Vars.spacing72)
        }

        longBodyLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Vars.paddingReg)
            make.top.equalTo(bodyLabel.snp.bottom).offset(Vars.spacing20)
        }

        semiBoldbodyLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Vars.paddingReg)
            make.top.equalTo(longBodyLabel.snp.bottom).offset(Vars.spacing20)
        }

        extraBoldBodyLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Vars.paddingReg)
            make.top.equalTo(semiBoldbodyLabel.snp.bottom).offset(Vars.spacing20)
        }

        captionLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Vars.paddingReg)
            make.top.equalTo(extraBoldBodyLabel.snp.bottom).offset(Vars.spacing20)
        }

        twoLineLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Vars.paddingReg)
            make.top.equalTo(captionLabel.snp.bottom).offset(Vars.spacing20)
        }

        tagLabel1.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(Vars.paddingReg)
            make.top.equalTo(twoLineLabel.snp.bottom).offset(Vars.spacing20)
        }

        tagLabel2.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(Vars.paddingReg)
            make.top.equalTo(tagLabel1.snp.bottom).offset(Vars.spacing20)
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    LabelSample2ViewController()
}
