//
//  TwoLineLabel.swift
//  DesignSystem
//
//  Created by MaxBook on 2/3/25.
//

import SnapKit
import Then
import UIKit

public class TwoLineLabel: UIView {
    // MARK: Lifecycle

    public init(text1: String, text2: String) {
        firstLineLabel = Headline3Label(weight: .extraBold).then {
            $0.text = text1
        }
        secondLineLabel = Headline3Label(weight: .extraBold).then {
            $0.text = text2
        }

        super.init(frame: .zero)

        setupViews()
        setupProperties()
        setupLayouts()
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    let firstLineLabel: Headline3Label
    let secondLineLabel: Headline3Label
}

// MARK: - UI Configure

extension TwoLineLabel {
    private func setupViews() {
        [
            firstLineLabel,
            secondLineLabel,
        ].forEach { self.addSubview($0) }
    }

    private func setupProperties() {
        backgroundColor = .clear
        secondLineLabel.textColor = Colors.brandMain
    }

    private func setupLayouts() {
        firstLineLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview()
        }

        secondLineLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.equalTo(firstLineLabel.snp.bottom).offset(Vars.spacing4)
            make.bottom.equalToSuperview()
        }
    }
}
