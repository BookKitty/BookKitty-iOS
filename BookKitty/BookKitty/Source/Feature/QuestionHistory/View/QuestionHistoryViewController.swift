//
//  QuestionHistoryViewController.swift
//  BookKitty
//  P-002
//
//  Created by 전성규 on 1/26/25.
//

import DesignSystem
import RxCocoa
import RxSwift
import SnapKit
import Then
import UIKit

final class QuestionHistoryViewController: BaseViewController {
    // MARK: Lifecycle

    init(viewModel: QuestionHistoryViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    override func bind() {
        let input = QuestionHistoryViewModel.Input(
            viewDidLoad: viewDidLoadRelay.asObservable(),
            questionSelected: questionTableView.rx.modelSelected(Question.self).asObservable(),
            reachedScrollEnd: questionTableView.rx.reachedBottom()
        )

        let output = viewModel.transform(input)

        output.questions
            .drive(questionTableView.rx.items(
                cellIdentifier: QuestionHistoryCell.identifier,
                cellType: QuestionHistoryCell.self
            )) { _, item, cell in
                cell.configure(with: item)
            }
            .disposed(by: disposeBag)
    }

    override func configureNavItem() {
        navigationItem.title = "QnA 히스토리"
    }

    override func configureHierarchy() {
        view.addSubview(questionTableView)
    }

    override func configureLayout() {
        questionTableView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }

    // MARK: Private

    private let viewModel: QuestionHistoryViewModel

    private lazy var questionTableView: UITableView = {
        let tableView = UITableView()
        tableView.register(
            QuestionHistoryCell.self,
            forCellReuseIdentifier: QuestionHistoryCell.identifier
        )
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 240

        return tableView
    }()
}

extension Reactive where Base: UIScrollView {
    fileprivate func reachedBottom() -> Observable<Void> {
        contentOffset
            .map { [weak base] offset in
                guard let base else {
                    return false
                }
                let contentHeight = base.contentSize.height
                let scrollViewHeight = base.bounds.height
                let threshold: CGFloat = 100
                return offset.y + scrollViewHeight + threshold > contentHeight
            }
            .distinctUntilChanged()
            .filter { $0 }
            .map { _ in () }
    }
}

@available(iOS 17.0, *)
#Preview {
    QuestionHistoryViewController(
        viewModel: QuestionHistoryViewModel(
            questionRepository: MockQuestionHistoryRepository()
        )
    )
}
