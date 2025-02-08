//
//  NewQuestionViewController.swift
//  BookKitty
//  P-004
//
//  Created by 전성규 on 2/3/25.
//

import DesignSystem
import RxCocoa
import RxSwift
import SnapKit
import Then
import UIKit

/// 사용자가 새로운 질문을 입력하고 제출할 수 있는 화면을 담당하는 ViewController
final class NewQuestionViewController: BaseViewController {
    // MARK: - Lifecycle

    init(viewModel: NewQuestionViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        bindQuestionInputView()
        bindKeyboard()
        setupTabGesture()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.navigationBar.isHidden = false
    }

    // MARK: - Internal

    override func bind() {
        guard let leftBarButtonItem = navigationItem.leftBarButtonItem?.customView as? UIButton
        else {
            return
        }

        let input = NewQuestionViewModel.Input(
            submitButtonTapped: submitButton.rx.tap
                .withLatestFrom(questionInputView.textView.rx.text.orEmpty).asObservable(),
            leftBarButtonTapTrigger: leftBarButtonItem.rx.tap.asObservable()
        )

        _ = viewModel.transform(input)
    }

    override func configureBackground() { view.backgroundColor = Colors.background0 }

    override func configureHierarchy() {
        [titleLabel, questionInputView, captionLabel, submitButton].forEach { view.addSubview($0) }
    }

    override func configureLayout() {
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).inset(Vars.paddingReg)
            $0.horizontalEdges.equalToSuperview().inset(Vars.paddingReg)
        }

        questionInputView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(Vars.spacing32)
            $0.horizontalEdges.equalToSuperview().inset(Vars.paddingReg)
            $0.height.equalTo(Vars.viewSizeHuge)
        }

        captionLabel.snp.makeConstraints {
            $0.top.equalTo(questionInputView.snp.bottom).offset(Vars.spacing32)
            $0.horizontalEdges.equalToSuperview().inset(Vars.paddingReg)
        }

        submitButton.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview().inset(Vars.paddingReg)
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
            $0.height.equalTo(Vars.viewSizeReg)
        }
    }

    override func configureNavItem() {
        var config = UIButton.Configuration.plain()
        config.title = "돌아가기"
        config.image = UIImage(systemName: "chevron.left")
        config.imagePlacement = .leading
        config.imagePadding = 5
        config.contentInsets = .zero

        let backButton = UIButton(configuration: config)
        backButton.tintColor = Colors.brandSub

        let backBarButtonItem = UIBarButtonItem(customView: backButton)

        navigationItem.leftBarButtonItem = backBarButtonItem
    }

    @objc
    func dismissKeyboard() { view.endEditing(true) }

    // MARK: - Private

    private let viewModel: NewQuestionViewModel

    private let titleLabel = TwoLineLabel(text1: "당신이 알고싶은 지식,", text2: "책냥이에게 물어보세요-!")
    private let questionInputView = QuestionTextView()
    private let captionLabel = CaptionLabel().then { $0.text = "당신이 궁금한 것들, 알고 싶은 지식을 자유롭게 적어주세요." }
    private let submitButton = RoundButton(title: "질문하기").then { $0.changeToDisabled() }

    /// questionInputView의 currentConut를 통해 입력 상태를 감지하여 submitButton 활성화를 관리하는 메서드
    ///
    /// - 입력된 텍스트가 없거나 100글자를 초과할 경우 submitButton 비활성화
    private func bindQuestionInputView() {
        questionInputView.currentCount
            .withUnretained(self)
            .bind(onNext: { owner, count in
                count == 0 || count > 100 ? owner.submitButton.changeToDisabled() : owner
                    .submitButton
                    .changeToEnabled()
            }).disposed(by: disposeBag)
    }

    private func setupTabGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
}

// MARK: - Keyboard

extension NewQuestionViewController {
    /// 키보드의 상태 변화를 감지하고 requestButton의 위치를 동적으로 조정하는 메서드
    ///
    /// RxSwift를 활용하여 NotificationCenter의 키보드 이벤트를 감지하고, UI 업데이트를 자동화함
    private func bindKeyboard() {
        let keyboardWillShow = NotificationCenter.default.rx
            .notification(UIResponder.keyboardWillShowNotification)
        let keyboardWillHide = NotificationCenter.default.rx
            .notification(UIResponder.keyboardWillHideNotification)

        // 키보드가 나타날 때 버튼 위치 조정
        keyboardWillShow
            .compactMap { notification -> (height: CGFloat, duration: TimeInterval)? in
                guard let userInfo = notification.userInfo,
                      let keyboardFrame =
                      userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
                      let duration =
                      userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval
                else {
                    return nil
                }
                return (keyboardFrame.height, duration)
            }
            .withUnretained(self)
            .subscribe(onNext: { owner, info in
                owner.updateButtonPosition(keyboardHeight: info.height, duration: info.duration)
            })
            .disposed(by: disposeBag)

        // 키보드가 사라질 때 버튼 위치 복귀
        keyboardWillHide
            .compactMap { notification -> TimeInterval? in
                notification
                    .userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval
            }
            .withUnretained(self)
            .subscribe(onNext: { owner, duration in
                owner.updateButtonPosition(keyboardHeight: 0.0, duration: duration)
            })
            .disposed(by: disposeBag)
    }

    /// 키보드 상태 변화에 따라 submitButton의 위치를 조정하는 메서드
    ///
    /// - 키보드가 올라오면 버튼을 키보드 바로 위로 이동
    /// - 키보드가 사라지면 버튼을 원래 위치로 복귀
    ///
    /// - Parameters:
    ///   - keyboardHeight: 현재 키보드의 높이 (0.0이면 키보드가 사라진 상태)
    ///   - duration: 키보드 애니메이션 지속 시간
    private func updateButtonPosition(keyboardHeight: CGFloat, duration: TimeInterval) {
        submitButton.snp.remakeConstraints {
            $0.height.equalTo(Vars.viewSizeReg)

            if keyboardHeight > 0.0 {
                $0.horizontalEdges.equalToSuperview()
                $0.bottom.equalToSuperview().offset(-keyboardHeight)
            } else {
                $0.horizontalEdges.equalToSuperview().inset(Vars.paddingReg)
                $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
            }
        }

        submitButton.toggleRadius()

        UIView.animate(withDuration: duration) { self.view.layoutIfNeeded() }
    }
}

@available(iOS 17.0, *)
#Preview {
    NewQuestionViewController(viewModel: NewQuestionViewModel())
}
