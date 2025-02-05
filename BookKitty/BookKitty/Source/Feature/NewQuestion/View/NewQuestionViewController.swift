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
    // MARK: Lifecycle

    init(viewModel: NewQuestionViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.navigationBar.isHidden = false
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    override func bind() {
//        guard let leftBarButtonItem = navigationItem.leftBarButtonItem?.customView as? UIButton
//        else {
//            return
//        }
//
//        let input = NewQuestionViewModel.Input(
//            submitButtonTapped: submitButton.rx.tap.withLatestFrom(testTextView.rx.value.orEmpty)
//                .asObservable(),
//            leftBarButtonTapTrigger: leftBarButtonItem.rx.tap.asObservable()
//        )
//
//        _ = viewModel.transform(input)
    }

    override func configureBackground() {
        view.backgroundColor = Colors.background0
    }

    override func configureHierarchy() {
        [titleLabel, questionInputView].forEach { view.addSubview($0) }
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
    }

    override func configureNavItem() {
        var config = UIButton.Configuration.plain()
        config.title = "돌아가기"
        config.image = UIImage(systemName: "chevron.left")
        config.imagePlacement = .leading
        config.imagePadding = 5
        config.contentInsets = .zero

        let backButton = UIButton(configuration: config)
        backButton.tintColor = .label

        let backBarButtonItem = UIBarButtonItem(customView: backButton)

        navigationItem.leftBarButtonItem = backBarButtonItem
    }

    @objc
    func dismissKeyboard() { view.endEditing(true) }

    // MARK: Private

    private let viewModel: NewQuestionViewModel

    private let titleLabel = TwoLineLabel(text1: "당신이 알고싶은 지식,", text2: "책냥이에게 물어보세요-!")
    private let questionInputView = QuestionTextView()
}

@available(iOS 17.0, *)
#Preview {
    NewQuestionViewController(viewModel: NewQuestionViewModel())
}
