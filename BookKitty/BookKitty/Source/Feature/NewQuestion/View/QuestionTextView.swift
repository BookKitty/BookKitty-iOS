//
//  QuestionTextView.swift
//  BookKitty
//
//  Created by 전성규 on 2/5/25.
//

import DesignSystem
import RxCocoa
import RxSwift
import SnapKit
import Then
import UIKit

/// 사용자가 질문을 입력할 수 있는 커스텀 텍스트뷰
///
/// - Placeholder 기능 제공
/// - 최대 글자 수 제한 (maximunCount)
/// - 입력한 글자 수를 countLabel에 실시간 업데이트
final class QuestionTextView: UIView {
    // MARK: Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)

        configureHierarchy()
        configureLayout()
        bindPlaceholder()
        bindTextCount()
        bindCountLabel()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    /// 현재 입력된 글자 수를 전달하는 PublishRelay
    let currentCount = PublishRelay<Int>()

    // MARK: Private

    /// 현재 Placeholder가 활성화 상태 여부
    private var isPlaceholderActive = true
    private let placeholder = "질문을 입력해주세요."
    private let maximunCount = 100
    private let disposeBag = DisposeBag()

    private lazy var countLabel = CaptionLabel().then { $0.text = "0 / 100" }

    private lazy var textView = UITextView().then {
        $0.font = Fonts.bodyRegular
        $0.text = placeholder
        $0.textColor = Colors.fontMain
        $0.textContainer.lineBreakMode = .byWordWrapping
        $0.textContainerInset = UIEdgeInsets(
            top: Vars.paddingSmall,
            left: Vars.paddingSmall,
            bottom: 42.0,
            right: Vars.paddingSmall
        )
        $0.backgroundColor = Colors.background1
        $0.layer.cornerRadius = Vars.radiusReg
    }

    private func configureHierarchy() {
        [textView, countLabel].forEach { addSubview($0) }
    }

    private func configureLayout() {
        textView.snp.makeConstraints { $0.edges.equalToSuperview() }

        countLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(Vars.paddingSmall)
            $0.bottom.equalToSuperview().inset(Vars.paddingSmall)
        }
    }

    // MARK: - Rx 바인딩

    /// Placeholder 활성화 및 비활성화를 관리하는 메서드
    ///
    /// - textView.rx.didBeginEditing을 감지하여 Placeholder 제거
    /// - textView.rx.didEndEditing을 감지하여 입력값이 없으면 Placeholder 복구
    private func bindPlaceholder() {
        textView.rx.didBeginEditing
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                guard owner.isPlaceholderActive else {
                    return
                }
                owner.isPlaceholderActive = false
                owner.textView.text = ""
            }).disposed(by: disposeBag)

        textView.rx.didEndEditing
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                guard owner.textView.text.isEmpty,
                      !owner.isPlaceholderActive else {
                    return
                }
                owner.isPlaceholderActive = true
                owner.textView.text = owner.placeholder
                owner.currentCount.accept(0) // 글자 수 초기화
            }).disposed(by: disposeBag)
    }

    /// 입력한 글자 수를 감지하고 최대 글자 수를 초과하지 않도록 제한하는 메서드
    ///
    /// - textView.rx.text.orEmpty를 감지하여 maximunCount 초과 시 입력 제한
    /// - 초과 입력이 발생하면 자동으로 textView.text를 잘라서 저장
    private func bindTextCount() {
        textView.rx.text.orEmpty
            .observe(on: MainScheduler.instance)
            .distinctUntilChanged()
            .withUnretained(self)
            .subscribe(onNext: { owner, text in
                let trimmedText = String(text.prefix(owner.maximunCount))
                if owner.textView.text != trimmedText {
                    owner.textView.text = trimmedText
                }
                owner.currentCount.accept(trimmedText.count) // 현재 글자 수 업데이트
            }).disposed(by: disposeBag)
    }

    /// 현재 입력된 글자 수를 countLabel에 업데이트하는 메서드
    ///
    /// - currentCount가 변경될 때 countLabel의 텍스트를 업데이트
    /// - maximunCount를 초과하면 글자 색상을 빨간색으로 변경
    private func bindCountLabel() {
        currentCount
            .observe(on: MainScheduler.instance)
            .distinctUntilChanged()
            .withUnretained(self)
            .subscribe(onNext: { owner, count in
                let newText = "\(count) / \(owner.maximunCount)"
                guard owner.countLabel.text != newText else {
                    return
                }
                owner.countLabel.text = newText
                owner.countLabel.textColor = count >= owner.maximunCount ? UIColor.red : Colors
                    .fontMain
            }).disposed(by: disposeBag)
    }
}
