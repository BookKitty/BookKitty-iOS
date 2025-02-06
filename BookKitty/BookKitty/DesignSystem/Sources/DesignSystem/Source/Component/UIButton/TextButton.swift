//
//  TextButton.swift
//  DesignSystem
//
//  Created by 임성수 on 1/29/25.
//

import SnapKit
import UIKit

public class TextButton: UIButton {
    // MARK: Lifecycle

    // MARK: - Initializer

    /// 텍스트만으로 이루어진 버튼
    /// 기본적으로 텍스트는 brandSub 색상을 가집니다.
    ///
    /// ``applyButtonAction`` 메소드를 사용하여 액션을 매핑할 수 있습니다.
    /// ``applyButtonAsyncAction`` 메소드를 사용하여 async 액션을 매핑할 수 있습니다.
    ///
    /// - Parameters:
    ///   - title: 버튼에 들어갈 텍스트입니다. 기본은 **바로가기**입니다.
    public init(title: String = "바로가기") {
        self.title = title
        super.init(frame: .zero)

        setupProperties()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    var title: String
}

// MARK: - Setup UI

extension TextButton {
    func setupProperties() {
        var config = UIButton.Configuration.plain()

        var titleContainer = AttributeContainer()
        titleContainer.font = Fonts.bodySemiBold

        titleContainer.underlineStyle = NSUnderlineStyle.single
        titleContainer.baselineOffset = Vars.spacing4

        config.attributedTitle = AttributedString(title, attributes: titleContainer)
        config.titleAlignment = .leading

        config.baseForegroundColor = Colors.brandSub
        configuration = config
    }
}

// MARK: - Methods

extension TextButton {
    public func setButtonTitle(_ newTitle: String) {
        var updatedConfig = configuration
        var titleContainer = AttributeContainer()
        titleContainer.font = Fonts.bodySemiBold

        updatedConfig?.attributedTitle = AttributedString(newTitle, attributes: titleContainer)
        configuration = updatedConfig
    }
}
