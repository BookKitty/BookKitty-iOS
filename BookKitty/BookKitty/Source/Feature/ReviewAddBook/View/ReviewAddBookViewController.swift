// ReviewAddBookViewController.swift

import DesignSystem
import RxCocoa
import RxSwift
import SnapKit
import Then
import UIKit

final class ReviewAddBookViewController: BaseViewController {
    // MARK: Lifecycle

    // MARK: - Init

    init(viewModel: ReviewAddBookViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Private

    // MARK: - Private Properties

    private let viewModel: ReviewAddBookViewModel
    private let deleteBookSubject = PublishSubject<Int>()
    private let manualTitleSubject = PublishSubject<String>()

    private let backButton = TextButton(title: "돌아가기")
    private let titleLabel = UILabel().then {
        $0.text = "촬영 결과"
        $0.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        $0.textAlignment = .center
    }

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewCompositionalLayout { [weak self] _, layoutEnvironment in
            var config = UICollectionLayoutListConfiguration(appearance: .plain)
            config.backgroundColor = .clear

            config.trailingSwipeActionsConfigurationProvider = { indexPath in
                let deleteAction = UIContextualAction(
                    style: .destructive,
                    title: nil
                ) { _, _, completion in
                    self?.deleteBookSubject.onNext(indexPath.item)
                    completion(true)
                }
                deleteAction.image = UIImage(systemName: "trash.fill")
                deleteAction.backgroundColor = .red
                return UISwipeActionsConfiguration(actions: [deleteAction])
            }

            return NSCollectionLayoutSection.list(
                using: config,
                layoutEnvironment: layoutEnvironment
            )
        }

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(BookCell.self, forCellWithReuseIdentifier: BookCell.identifier)
        collectionView.backgroundColor = .clear
        return collectionView
    }()

    private let missingBookLabel = BodyLabel().then {
        $0.text = "누락된 책이 있나요?\n책의 제목을 입력하여 직접 책을 추가하세요."
        $0.textAlignment = .left
        $0.numberOfLines = 2
    }

    private let addBookButton = TextButton(title: "+ 책 추가하기")
    private let confirmButton = RoundButton(title: "추가 완료")

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = .white
        view.addSubview(backButton)
        view.addSubview(titleLabel)
        view.addSubview(collectionView)
        view.addSubview(missingBookLabel)
        view.addSubview(addBookButton)
        view.addSubview(confirmButton)
    }

    // MARK: - Constraints

    private func setupConstraints() {
        backButton.snp.makeConstraints {
            $0.top.leading.equalTo(view.safeAreaLayoutGuide).inset(16)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(backButton.snp.bottom).offset(10)
            $0.centerX.equalToSuperview()
        }

        collectionView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalTo(confirmButton.snp.top).offset(-80)
        }

        missingBookLabel.snp.makeConstraints {
            $0.top.equalTo(collectionView.snp.bottom).offset(20)
            $0.leading.equalToSuperview().inset(20)
        }

        addBookButton.snp.makeConstraints {
            $0.top.equalTo(missingBookLabel.snp.bottom).offset(4)
            $0.leading.equalTo(missingBookLabel.snp.leading)
        }

        confirmButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            $0.height.equalTo(48)
        }
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
            .observe(on: MainScheduler.instance)
            .bind(to: collectionView.rx.items(
                cellIdentifier: BookCell.identifier,
                cellType: BookCell.self
            )) { [weak self] index, book, cell in
                cell.configure(with: book)

                if index == output.bookList.value.count - 1 {
                    self?.updateMissingBookUI(below: cell)
                }
            }
            .disposed(by: disposeBag)

        addBookButton.rx.tap
            .bind { [weak self] in
                self?.showManualTitleInput()
            }
            .disposed(by: disposeBag)

        confirmButton.rx.tap
            .bind { [weak self] in
                self?.dismiss(animated: true)
            }
            .disposed(by: disposeBag)
    }

    // MARK: - Update UI for Missing Book Section

    private func updateMissingBookUI(below cell: UICollectionViewCell) {
        missingBookLabel.snp.remakeConstraints {
            $0.top.equalTo(cell.snp.bottom).offset(20)
            $0.leading.equalToSuperview().inset(20)
        }

        addBookButton.snp.remakeConstraints {
            $0.top.equalTo(missingBookLabel.snp.bottom).offset(4)
            $0.leading.equalTo(missingBookLabel.snp.leading)
        }
    }

    // MARK: - Show Manual Title Input

    private func showManualTitleInput() {
        let alert = UIAlertController(
            title: "책 제목으로 직접 추가하기",
            message: "책의 제목을 입력해주세요.",
            preferredStyle: .alert
        )
        alert.addTextField()

        let addAction = UIAlertAction(title: "확인", style: .default) { [weak self] _ in
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

// MARK: - BookCell

final class BookCell: UICollectionViewCell {
    // MARK: Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
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
        $0.textColor = .black
        $0.numberOfLines = 1
    }

    private let authorLabel = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        $0.textColor = .darkGray
        $0.numberOfLines = 1
    }

    private func setupUI() {
        contentView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.1)
        contentView.layer.cornerRadius = 8
        contentView.addSubview(titleLabel)
        contentView.addSubview(authorLabel)
    }

    private func setupConstraints() {
        contentView.snp.makeConstraints {
            $0.width.equalTo(354)
            $0.height.equalTo(72)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.width.equalTo(257.74)
            $0.height.equalTo(46)
        }

        authorLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(4)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
    }
}
