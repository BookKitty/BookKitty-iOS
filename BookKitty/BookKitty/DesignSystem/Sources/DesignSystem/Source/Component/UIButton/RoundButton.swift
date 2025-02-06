//
//  RoundButton.swift
//  DesignSystem
//
//  Created by 임성수 on 1/29/25.
//

import SnapKit
import UIKit

public class RoundButton: UIButton {
    // MARK: Lifecycle

    // MARK: - Initializer

    /// 기본 형태의 버튼.
    /// 기본적으로 brandSub 색상을 가집니다.
    ///
    /// ``applyButtonAction`` 메소드를 사용하여 액션을 매핑할 수 있습니다.
    /// ``applyButtonAsyncAction`` 메소드를 사용하여 async 액션을 매핑할 수 있습니다.
    ///
    /// - Parameters:
    ///   - title: 버튼에 들어갈 텍스트입니다. 기본은 **확인**입니다.
    ///   - isSecondary: 버튼 색상에 투명도 여부입니다. true일 경우 30% 투명도를 가지고 있습니다.
    public init(title: String = "확인", isSecondary: Bool = false) {
        self.title = title
        self.isSecondary = isSecondary
        super.init(frame: .zero)

        setupProperties()
        setupLayouts()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    var title: String
    var isSecondary: Bool
    var isRounded = true
}

// MARK: - Setup UI

extension RoundButton {
    func setupProperties() {
        var config = UIButton.Configuration.filled()

        var titleContainer = AttributeContainer()
        titleContainer.font = Fonts.bodySemiBold

        config.attributedTitle = AttributedString(title, attributes: titleContainer)
        config.titleAlignment = .center
        config.background.cornerRadius = Vars.radiusMini

        config.baseForegroundColor = Colors.fontWhite
        config.baseBackgroundColor = isSecondary ? Colors.brandSub30 : Colors.brandSub
        config.contentInsets = NSDirectionalEdgeInsets(
            top: Vars.spacing4,
            leading: Vars.paddingSmall,
            bottom: Vars.spacing4,
            trailing: Vars.paddingSmall
        )

        configuration = config
    }

    func setupLayouts() {
        snp.makeConstraints { make in
            make.height.equalTo(Vars.viewSizeReg)
            make.width.greaterThanOrEqualTo(80)
        }
    }
}

// MARK: - Methods

extension RoundButton {
    public func changeToDisabled() {
        var disabledConfig = configuration
        disabledConfig?.baseBackgroundColor = Colors.systemGray(.r100)
        isEnabled = false
        configuration = disabledConfig
    }

    public func changeToEnabled() {
        var enabledConfig = configuration
        enabledConfig?.baseBackgroundColor = Colors.brandSub
        isEnabled = true
        configuration = enabledConfig
    }

    public func toggleRadius() {
        var config = configuration
        isRounded = !isRounded
        config?.background.cornerRadius = isRounded ? Vars.radiusMini : 0
        configuration = config
    }

    public func changeBackgroundColor(to color: UIColor) {
        var config = configuration
        config?.baseBackgroundColor = color
        configuration = config
    }

    public func setButtonTitle(_ newTitle: String) {
        var updatedConfig = configuration
        var titleContainer = AttributeContainer()
        titleContainer.font = Fonts.bodySemiBold

        updatedConfig?.attributedTitle = AttributedString(newTitle, attributes: titleContainer)
        configuration = updatedConfig
    }
}
