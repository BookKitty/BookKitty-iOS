//
//  CircleIconButton.swift
//  DesignSystem
//
//  Created by 임성수 on 2/2/25.
//

import SnapKit
import UIKit

public class CircleIconButton: UIButton {
    // MARK: Lifecycle

    // MARK: - Initializer

    /// 기본 형태의 버튼.
    /// 기본적으로 brandSub 색상을 가집니다.
    ///
    /// ``applyButtonAction`` 메소드를 사용하여 액션을 매핑할 수 있습니다.
    /// ``applyButtonAsyncAction`` 메소드를 사용하여 async 액션을 매핑할 수 있습니다.
    ///
    /// - Parameters:
    ///   - iconId: 버튼에 들어갈 이미지 sf symbols 아이디입니다.
    public init(iconId: String = "xmark.triangle.circle.square") {
        self.iconId = iconId
        super.init(frame: .zero)

        setupProperties()
        setupLayouts()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    var iconId: String
}

// MARK: - Setup UI

extension CircleIconButton {
    private func setupProperties() {
        var config = UIButton.Configuration.filled()

        config.background.cornerRadius = Vars.radiusLarge

        config.baseForegroundColor = Colors.fontWhite
        config.baseBackgroundColor = Colors.brandSub

        config.image = UIImage(systemName: iconId)
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(
            pointSize: 32,
            weight: .medium
        )

        configuration = config
    }

    private func setupLayouts() {
        snp.makeConstraints { make in
            make.width.height.equalTo(Vars.viewSizeLarge)
        }
    }
}

// MARK: - Methods

extension CircleIconButton {
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

    public func setButtonIcon(_ newIcon: String) {
        var updatedConfig = configuration

        updatedConfig?.image = UIImage(systemName: newIcon)
        configuration = updatedConfig
    }

    public func changeBackgroundColor(to color: UIColor) {
        var config = configuration
        config?.baseBackgroundColor = color
        configuration = config
    }
}
