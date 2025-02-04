//
//  NewQuestionViewController.swift
//  BookKitty
//  P-004
//
//  Created by 전성규 on 2/3/25.
//

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

    override func bind() {
        guard let leftBarButtonItem = navigationItem.leftBarButtonItem?.customView as? UIButton
        else {
            return
        }

        let input = NewQuestionViewModel.Input(
            submitButtonTapped: submitButton.rx.tap.withLatestFrom(testTextView.rx.value.orEmpty)
                .asObservable(),
            leftBarButtonTapTrigger: leftBarButtonItem.rx.tap.asObservable()
        )

        _ = viewModel.transform(input)
    }

    override func configureHierarchy() {
        [testTextView, submitButton].forEach { view.addSubview($0) }
    }

    override func configureLayout() {
        testTextView.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview().inset(24.0)
            $0.centerY.equalToSuperview()
            $0.height.equalTo(300.0)
        }

        submitButton.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview().inset(24.0)
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
            $0.height.equalTo(48.0)
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

    // MARK: Private

    private let viewModel: NewQuestionViewModel

    private let testTextView = UITextView().then {
        $0.backgroundColor = .lightGray
    }

    private let submitButton = UIButton().then {
        $0.setTitle("질문하기", for: .normal)
        $0.setTitleColor(.white, for: .normal)
        $0.backgroundColor = .tintColor
    }
}

@available(iOS 17.0, *)
#Preview {
    NewQuestionViewController(viewModel: NewQuestionViewModel())
}
