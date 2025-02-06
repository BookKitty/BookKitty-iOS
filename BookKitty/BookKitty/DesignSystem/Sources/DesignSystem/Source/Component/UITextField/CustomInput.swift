//
//  CustomInput.swift
//  DesignSystem
//
//  Created by 임성수 on 2/4/25.
//

import SnapKit
import Then
import UIKit

public class CustomInput: UITextField {
    // MARK: Lifecycle

    // MARK: - Initializer

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupProperties()
        setupLayouts()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Public

    public let placeholderText = "책의 제목을 입력해주세요."
}

// MARK: - Setup UI

extension CustomInput {
    private func setupProperties() {
        placeholder = placeholderText
        layer.cornerRadius = Vars.radiusMini
        backgroundColor = Colors.background1
        font = Fonts.bodyRegular
        textColor = Colors.fontMain
        textAlignment = .center
        leftView = UIView(frame: .init(x: 0, y: 0, width: 10, height: 10))
        leftViewMode = .always
        rightView = UIView(frame: .init(x: 0, y: 0, width: 10, height: 10))
        rightViewMode = .always
    }

    private func setupLayouts() {
        snp.makeConstraints { make in
            make.height.equalTo(Vars.viewSizeReg)
        }
    }
}
