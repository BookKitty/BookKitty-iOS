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
    // MARK: - Properties

    // MARK: - Private

    private let viewModel: QuestionHistoryViewModel

    private let titleLabel = Headline1Label(weight: .extraBold).then {
        $0.text = "QnA 히스토리"
        $0.textColor = Colors.fontMain
    }

    private lazy var questionTableView: UITableView = {
        let tableView = UITableView()
        tableView.register(
            QuestionHistoryCell.self,
            forCellReuseIdentifier: QuestionHistoryCell.identifier
        )
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 240
        tableView.showsVerticalScrollIndicator = false

        return tableView
    }()

    // MARK: - Lifecycle

    init(viewModel: QuestionHistoryViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Overridden Functions

    // MARK: - Internal

    override func bind() {
        let input = QuestionHistoryViewModel.Input(
            viewWillAppear: viewWillAppearRelay.asObservable(),
            questionSelected: questionTableView.rx.modelSelected(QuestionAnswer.self)
                .asObservable(),
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

        output.questions
            .skip(1) // VM에 위치한 기본 빈 배열 무시
            .map { questions -> UIView? in
                if questions.isEmpty {
                    let containerView = UIView()
                    let emptyView = EmptyDataDescriptionView(with: .question)

                    containerView.addSubview(emptyView)
                    emptyView.snp.makeConstraints { $0.center.equalToSuperview() }

                    return containerView
                } else {
                    return nil // 질문 목록이 있으면 배경 제거
                }
            }.drive(questionTableView.rx.backgroundView)
            .disposed(by: disposeBag)
    }

    override func configureHierarchy() {
        view.addSubview(questionTableView)

        // titleLabel을 포함할 containerView 생성
        let headerView = UIView(frame: CGRect(
            x: 0,
            y: 0,
            width: view.bounds.width,
            height: 42 + Vars.paddingReg
        ))
        headerView.addSubview(titleLabel)

        // titleLabel 제약조건 설정
        titleLabel.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalToSuperview().inset(Vars.paddingSmall)
        }

        questionTableView.tableHeaderView = headerView
    }

    override func configureLayout() {
        questionTableView.snp.makeConstraints { make in
            make.verticalEdges.equalTo(view.safeAreaLayoutGuide)
            make.horizontalEdges.equalTo(view.safeAreaLayoutGuide).inset(Vars.paddingSmall)
        }
    }
}

extension Reactive where Base: UIScrollView {
    fileprivate func reachedBottom() -> Observable<Void> {
        contentOffset
            .skip(1)
            .filter { [weak base] _ in
                guard let base else {
                    return false
                }
                return base.contentSize.height > base.bounds.height
            }
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
            questionHistoryRepository: MockQuestionHistoryRepository()
        )
    )
}
