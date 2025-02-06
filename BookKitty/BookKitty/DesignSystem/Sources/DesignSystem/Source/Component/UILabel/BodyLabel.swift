//
//  BodyLabel.swift
//  DesignSystem
//
//  Created by 임성수 on 1/29/25.
//

import SnapKit
import UIKit

public class BodyLabel: UILabel {
    // MARK: Lifecycle

    public init(weight: FontWeight = .regular) {
        self.weight = weight
        super.init(frame: .zero)

        setupProperties()
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Public

    override public var text: String? {
        didSet { updateAttributes() }
    }

    override public var textColor: UIColor? {
        didSet { updateAttributes() }
    }

    // MARK: Internal

    var weight: FontWeight {
        didSet { updateAttributes() }
    }
}

// MARK: - UI Configure

extension BodyLabel {
    private func setupProperties() {
        backgroundColor = .clear
        textColor = Colors.fontMain
        textAlignment = .left
        numberOfLines = 0

        updateAttributes()
    }

    private func updateAttributes() {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 8
        paragraphStyle.alignment = textAlignment

        let attributes: [NSAttributedString.Key: Any] = [
            .font: getFontForWeight(weight),
            .foregroundColor: textColor ?? Colors.fontMain,
            .paragraphStyle: paragraphStyle,
        ]

        if let text {
            attributedText = NSAttributedString(string: text, attributes: attributes)
        }
    }

    private func getFontForWeight(_ weight: FontWeight) -> UIFont {
        switch weight {
        case .regular:
            return Fonts.bodyRegular
        case .semiBold:
            return Fonts.bodySemiBold
        case .extraBold:
            return Fonts.bodyExtraBold
        }
    }
}
