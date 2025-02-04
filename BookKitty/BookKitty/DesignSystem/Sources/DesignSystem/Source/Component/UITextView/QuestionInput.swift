//
//  QuestionInput.swift
//  DesignSystem
//
//  Created by MaxBook on 2/3/25.
//

import SnapKit
import Then
import UIKit

@available(iOS 15.0, *)
public class QuestionInput: UIView, UITextViewDelegate {
    // MARK: Lifecycle

    // MARK: - Initializer

    public init(text: String = "") {
        self.text = text
        super.init(frame: .zero)

        setupViews()
        setupLayouts()
        textView.delegate = self
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Public

    public let maxCharacterLimit = 100
    public let placeholderText = "입력해주세요"

    public var textView = UITextView().then {
        $0.font = Fonts.bodyRegular
        $0.textColor = Colors.fontMain
        $0.backgroundColor = Colors.background1
        $0.layer.cornerRadius = Vars.radiusReg
        $0.textContainerInset = Vars.setContainerInset(Vars.paddingSmall)
        $0.isEditable = true
        $0.isUserInteractionEnabled = true
    }

    public lazy var characterCountLabel = CaptionLabel().then {
        $0.text = "0 / \(maxCharacterLimit)"
    }

    public lazy var placeholderLabel = BodyLabel().then {
        $0.textColor = Colors.fontSub2
        $0.text = placeholderText
        $0.isHidden = false
    }

    public var text: String? {
        didSet { updateAttributes() }
    }
}

// MARK: - Setup UI

@available(iOS 15.0, *)
extension QuestionInput {
    private func setupViews() {
        [
            textView,
            characterCountLabel,
            placeholderLabel,
        ].forEach { self.addSubview($0) }
    }

    private func setupLayouts() {
        snp.makeConstraints { make in
            make.height.equalTo(Vars.viewSizeHuge)
        }

        textView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        placeholderLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(Vars.paddingSmall)
            make.left.equalToSuperview().inset(Vars.paddingSmall)
        }

        characterCountLabel.snp.makeConstraints { make in
            make.bottom.equalTo(textView).inset(Vars.paddingSmall)
            make.right.equalTo(textView).inset(Vars.paddingSmall)
        }
    }

    // MARK: - Text formatting

    private func updateAttributes() {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 8
        paragraphStyle.alignment = .left

        let attributes: [NSAttributedString.Key: Any] = [
            .font: Fonts.bodyRegular,
            .foregroundColor: Colors.fontMain,
            .paragraphStyle: paragraphStyle,
        ]

        if let text {
            textView.attributedText = NSAttributedString(string: text, attributes: attributes)
        }
    }

    // MARK: - UITextViewDelegate

    public func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty

        let textCount = textView.text.count
        characterCountLabel.text = "\(textCount) / \(maxCharacterLimit)"

        if textCount > maxCharacterLimit {
            textView.text = String(textView.text.prefix(maxCharacterLimit))
        }
    }

    public func textViewDidBeginEditing(_: UITextView) {
        placeholderLabel.isHidden = true
    }

    public func textViewDidEndEditing(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
    }
}
