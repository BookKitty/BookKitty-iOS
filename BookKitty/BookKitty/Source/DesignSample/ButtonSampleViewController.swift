//
//  ButtonSampleViewController 2.swift
//  BookKitty
//
//  Created by 임성수 on 2/3/25.
//

import DesignSystem
import SnapKit
import Then
import UIKit

class ButtonSampleViewController: BaseViewController {
    // MARK: - Properties

    // MARK: - Internal

    let confirmButton = RoundButton()
    let cancelButton = RoundButton(title: "취소, 너비 지정 없음", isSecondary: true)
    let customButton = RoundButton(title: "색상 바꾼 버튼").then {
        $0.changeBackgroundColor(to: Colors.brandMain)
    }

    let disabledButton = RoundButton(title: "Disabled button").then {
        $0.changeToDisabled()
    }

    let squareButton = RoundButton(title: "모서리 뾰족하게 토글").then {
        $0.toggleRadius()
    }

    let iconButton1 = CircleIconButton()
    let iconButton2 = CircleIconButton(iconId: "microphone.fill")

    let textButton1 = TextButton()
    let textButton2 = TextButton(title: "+ 책 추가하기")

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupProperties()
        setupLayouts()
    }
}

// MARK: - UI Configure

extension ButtonSampleViewController {
    private func setupViews() {
        [
            confirmButton,
            cancelButton,
            customButton,
            disabledButton,
            squareButton,
            iconButton1,
            iconButton2,
            textButton1,
            textButton2,
        ].forEach { view.addSubview($0) }
    }

    private func setupProperties() {
        view.backgroundColor = Colors.statusRed
        confirmButton.applyButtonAction(action: {
            print("tapped!")
        })
        disabledButton.applyButtonAction(action: { print("tapped!") })
    }

    private func setupLayouts() {
        confirmButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Vars.paddingReg)
            make.top.equalToSuperview().inset(Vars.spacing72)
        }

        cancelButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(Vars.paddingReg)
            make.top.equalTo(confirmButton.snp.bottom).offset(Vars.spacing20)
        }

        customButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Vars.paddingReg)
            make.top.equalTo(cancelButton.snp.bottom).offset(Vars.spacing20)
        }

        disabledButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Vars.paddingReg)
            make.top.equalTo(customButton.snp.bottom).offset(Vars.spacing20)
        }

        squareButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Vars.paddingReg)
            make.top.equalTo(disabledButton.snp.bottom).offset(Vars.spacing20)
        }

        iconButton1.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(Vars.paddingReg)
            make.top.equalTo(squareButton.snp.bottom).offset(Vars.spacing20)
        }

        iconButton2.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(Vars.paddingReg)
            make.top.equalTo(iconButton1.snp.bottom).offset(Vars.spacing20)
        }

        textButton1.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(Vars.paddingReg)
            make.top.equalTo(iconButton2.snp.bottom).offset(Vars.spacing20)
        }

        textButton2.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(Vars.paddingReg)
            make.top.equalTo(textButton1.snp.bottom).offset(Vars.spacing20)
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    ButtonSampleViewController()
}
