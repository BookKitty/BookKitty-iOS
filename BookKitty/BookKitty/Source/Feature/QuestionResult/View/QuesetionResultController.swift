//
//  QuesetionResultController.swift
//  BookKitty
//  P-005
//
//  Created by 전성규 on 2/3/25.
//

import RxCocoa
import RxSwift
import SnapKit
import Then
import UIKit

final class QuestionResultViewController: BaseViewController {
    // MARK: Lifecycle

    init(viewModel: QuestionResultViewModel) {
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

        navigationController?.navigationBar.isHidden = true
    }

    override func bind() {
        let input = QuestionResultViewModel.Input(
            viewDidLoad: viewDidLoadRelay.asObservable(),
            bookThumbnailButtonTapTigger: bookThumbnailButton.rx.tap
                .map { _ in "isbn" } // TODO: Cell에 저장된 model에서 isbn 가져오기
                .asObservable(),
            confirmButtonTrigger: confirmButton.rx.tap.asObservable()
        )

        let output = viewModel.transform(input)

        output.question
            .asObservable()
            .bind(to: questionLabel.rx.text)
            .disposed(by: disposeBag)
    }

    override func configureHierarchy() {
        [testLabel, questionLabel, bookThumbnailButton, confirmButton]
            .forEach { view.addSubview($0) }
    }

    override func configureLayout() {
        testLabel.snp.makeConstraints { $0.center.equalToSuperview() }

        questionLabel.snp.makeConstraints {
            $0.top.equalTo(testLabel.snp.bottom).offset(20.0)
            $0.centerX.equalToSuperview()
        }

        bookThumbnailButton.snp.makeConstraints {
            $0.top.equalTo(questionLabel.snp.bottom).offset(20.0)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(150.0)
            $0.height.equalTo(150.0)
        }

        confirmButton.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview().inset(24.0)
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
            $0.height.equalTo(48.0)
        }
    }

    // MARK: Private

    private let viewModel: QuestionResultViewModel

    private let testLabel = UILabel().then {
        $0.text = "P-005"
        $0.font = .systemFont(ofSize: 30.0, weight: .bold)
    }

    private let questionLabel = UILabel()

    private let bookThumbnailButton = UIButton().then {
        $0.setTitle("Book Thumbnail", for: .normal)
        $0.backgroundColor = .tintColor
    }

    private let confirmButton = UIButton().then {
        $0.setTitle("답변 확인을 완료합니다.", for: .normal)
        $0.backgroundColor = .tintColor
    }
}
