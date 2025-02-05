//
//  ReviewAddBookViewController.swift
//  BookKitty
//
//  Created by 반성준 on 1/31/25.
//

import RxCocoa
import RxSwift
import SnapKit
import Then
import UIKit

final class ReviewAddBookViewController: BaseViewController, UITableViewDelegate {
    // MARK: Lifecycle

    init(viewModel: ReviewAddBookViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupTableView()
        bindViewModel()
    }

    // MARK: - Swipe to Delete (밀어서 삭제)

    func tableView(
        _: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(
            style: .destructive,
            title: nil
        ) { [weak self] _, _, completionHandler in
            self?.deleteBookSubject.onNext(indexPath.row)
            completionHandler(true)
        }
        deleteAction.image = UIImage(systemName: "trash.fill") // 휴지통 아이콘 추가
        deleteAction.backgroundColor = .red // 빨간색 배경

        return UISwipeActionsConfiguration(actions: [deleteAction])
    }

    // MARK: Private

    // MARK: - Private Properties

    private let viewModel: ReviewAddBookViewModel
    private let manualTitleSubject = PublishSubject<String>()
    private let deleteBookSubject = PublishSubject<Int>()

    private let backButton = UIButton().then {
        $0.setTitle("← 돌아가기", for: .normal)
        $0.setTitleColor(.systemTeal, for: .normal)
    }

    private let titleLabel = UILabel().then {
        $0.text = "촬영 결과"
        $0.font = UIFont.boldSystemFont(ofSize: 20)
        $0.textAlignment = .center
    }

    private let bookListView = UITableView().then {
        $0.register(BookCell.self, forCellReuseIdentifier: BookCell.identifier)
        $0.separatorStyle = .none
        $0.backgroundColor = .clear
    }

    private let missingBookLabel = UILabel().then {
        $0.text = "누락된 책이 있나요?\n책의 제목을 입력하여 직접 책을 추가하세요."
        $0.font = UIFont.systemFont(ofSize: 14)
        $0.textColor = .black
        $0.numberOfLines = 2
    }

    private let addBookButton = UIButton().then {
        $0.setTitle("+ 책 추가하기", for: .normal)
        $0.setTitleColor(.systemGreen, for: .normal)
        $0.contentHorizontalAlignment = .leading
    }

    private let confirmButton = UIButton().then {
        $0.setTitle("추가 완료", for: .normal)
        $0.setTitleColor(.white, for: .normal)
        $0.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.7)
        $0.layer.cornerRadius = 8
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = .white
        view.addSubview(backButton)
        view.addSubview(titleLabel)
        view.addSubview(bookListView)
        view.addSubview(confirmButton)

        setupTableFooter()
    }

    private func setupTableFooter() {
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 150))
        footerView.addSubview(missingBookLabel)
        footerView.addSubview(addBookButton)

        missingBookLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.leading.equalToSuperview().inset(20)
        }

        addBookButton.snp.makeConstraints {
            $0.top.equalTo(missingBookLabel.snp.bottom).offset(12)
            $0.leading.equalToSuperview().inset(20)
        }

        bookListView.tableFooterView = footerView
    }

    private func setupConstraints() {
        backButton.snp.makeConstraints {
            $0.top.leading.equalTo(view.safeAreaLayoutGuide).inset(16)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(backButton.snp.bottom).offset(10)
            $0.centerX.equalToSuperview()
        }

        bookListView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalTo(confirmButton.snp.top).offset(-20)
        }

        confirmButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            $0.height.equalTo(48)
        }
    }

    private func setupTableView() {
        bookListView.delegate = self
    }

    // MARK: - ViewModel Binding

    private func bindViewModel() {
        let input = ReviewAddBookViewModel.Input(
            confirmButtonTapped: confirmButton.rx.tap.asObservable(),
            addBookWithTitleTapped: manualTitleSubject.asObservable(),
            deleteBookTapped: deleteBookSubject.asObservable()
        )

        let output = viewModel.transform(input)

        output.bookList
            .bind(to: bookListView.rx.items(
                cellIdentifier: BookCell.identifier,
                cellType: BookCell.self
            )) { _, book, cell in
                cell.configure(with: book)
            }
            .disposed(by: disposeBag)

        output.navigateToBookList
            .bind { [weak self] in
                self?.dismiss(animated: true)
            }
            .disposed(by: disposeBag)

        addBookButton.rx.tap
            .bind { [weak self] in
                self?.showManualTitleInput()
            }
            .disposed(by: disposeBag)

        backButton.rx.tap
            .bind { [weak self] in
                self?.dismiss(animated: true)
            }
            .disposed(by: disposeBag)
    }

    // MARK: - Show Manual Title Input

    private func showManualTitleInput() {
        let alert = UIAlertController(
            title: "책 제목 입력",
            message: "책 제목을 입력해주세요.",
            preferredStyle: .alert
        )
        alert.addTextField()

        let addAction = UIAlertAction(title: "추가", style: .default) { [weak self] _ in
            if let title = alert.textFields?.first?.text, !title.isEmpty {
                self?.manualTitleSubject.onNext(title)
            }
        }
        let cancelAction = UIAlertAction(title: "취소", style: .cancel)

        alert.addAction(addAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }
}

// MARK: - BookCell (Custom TableView Cell)

final class BookCell: UITableViewCell {
    // MARK: Lifecycle

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        setupConstraints()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    static let identifier = "BookCell"

    func configure(with book: Book) {
        titleLabel.text = book.title
        authorLabel.text = "\(book.author) 지음"
    }

    // MARK: Private

    private let titleLabel = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
    }

    private let authorLabel = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        $0.textColor = .darkGray
    }

    private func setupUI() {
        selectionStyle = .none
        contentView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.1) // ✅ 아주 연한 회색 배경 적용
        contentView.layer.cornerRadius = 8 // ✅ 모서리 둥글게
        contentView.layer.masksToBounds = true // ✅ 둥근 모서리를 유지하도록 설정

        contentView.addSubview(titleLabel)
        contentView.addSubview(authorLabel)
    }

    private func setupConstraints() {
        contentView.snp.makeConstraints {
            $0.width.equalTo(354) // ✅ 지정된 크기 유지
            $0.height.equalTo(72)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().inset(10)
            $0.leading.equalToSuperview().inset(10)
        }

        authorLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(5)
            $0.leading.equalTo(titleLabel.snp.leading)
        }
    }
}
