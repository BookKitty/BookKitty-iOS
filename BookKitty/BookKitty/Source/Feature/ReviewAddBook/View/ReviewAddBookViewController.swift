// ReviewAddBookViewController.swift

import DesignSystem
import RxCocoa
import RxDataSources
import RxSwift
import SnapKit
import Then
import UIKit

final class ReviewAddBookViewController: BaseViewController {
    // MARK: - Lifecycle

    // MARK: - Init

    init(viewModel: ReviewAddBookViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Internal

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        bindViewModel()
    }

    func appendBook(_ book: Book) {
        guard !addedBookTitles.contains(book.title) else {
            return
        }
        addedBookTitles.insert(book.title)
        viewModel.appendBook(book)
    }

    // MARK: - Private

    // MARK: - Private Properties

    private let viewModel: ReviewAddBookViewModel
    private let deleteBookSubject = PublishSubject<Int>()
    private let manualTitleSubject = PublishSubject<String>()
    private var addedBookTitles = Set<String>()

    private let titleLabel = UILabel().then {
        $0.text = "촬영 결과"
        $0.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        $0.textAlignment = .left
    }

    private lazy var collectionView: UICollectionView = {
        let config = UICollectionLayoutListConfiguration(appearance: .plain)
        var layoutConfig = config
        layoutConfig.trailingSwipeActionsConfigurationProvider = { [weak self] indexPath in
            return self?.swipeActionsConfiguration(for: indexPath)
        }
        let layout = UICollectionViewCompositionalLayout.list(using: layoutConfig)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .white
        collectionView.register(BookCell.self, forCellWithReuseIdentifier: BookCell.identifier)
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
        view.addSubview(titleLabel)
        view.addSubview(collectionView)
        view.addSubview(missingBookLabel)
        view.addSubview(addBookButton)
        view.addSubview(confirmButton)
    }

    private func setupConstraints() {
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            $0.leading.equalToSuperview().inset(20)
        }

        collectionView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalTo(missingBookLabel.snp.top).offset(-16)
        }

        confirmButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            $0.height.equalTo(48)
        }

        missingBookLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(20)
            $0.bottom.equalTo(addBookButton.snp.top).offset(-4)
        }

        addBookButton.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(20)
            $0.bottom.equalTo(confirmButton.snp.top).offset(-16)
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

        let dataSource = RxCollectionViewSectionedReloadDataSource<SectionModel<String, Book>>(
            configureCell: { _, collectionView, indexPath, book in
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: BookCell.identifier,
                    for: indexPath
                ) as! BookCell
                cell.configure(with: book)
                return cell
            }
        )

        output.bookList
            .map { [SectionModel(model: "Books", items: $0)] }
            .bind(to: collectionView.rx.items(dataSource: dataSource))
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

    private func swipeActionsConfiguration(for indexPath: IndexPath)
        -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(
            style: .destructive,
            title: "삭제"
        ) { [weak self] _, _, completion in
            self?.deleteBookSubject.onNext(indexPath.item)
            completion(true)
        }
        deleteAction.image = UIImage(systemName: "trash.fill")
        deleteAction.backgroundColor = .red

        return UISwipeActionsConfiguration(actions: [deleteAction])
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
    // MARK: - Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Internal

    static let identifier = "BookCell"

    func configure(with book: Book) {
        titleLabel.text = book.title
        authorLabel.text = "\(book.author) 지음"

        if let imageUrl = book.thumbnailUrl {
            bookImageView.loadImage(from: imageUrl)
        } else {
            bookImageView.image = UIImage(named: "default_book")
        }
    }

    // MARK: - Private

    private let bookImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.layer.cornerRadius = 4
        $0.clipsToBounds = true
        $0.backgroundColor = UIColor.lightGray.withAlphaComponent(0.05) // ✅ 투명 회색 배경
    }

    private let titleLabel = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        $0.textColor = .black
        $0.numberOfLines = 2
        $0.textAlignment = .left
        $0.adjustsFontSizeToFitWidth = true // ✅ 글자 크기 자동 조정
        $0.minimumScaleFactor = 0.9
    }

    private let authorLabel = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        $0.textColor = .darkGray
        $0.textAlignment = .left
        $0.adjustsFontSizeToFitWidth = true // ✅ 글자 크기 자동 조정
        $0.minimumScaleFactor = 0.9
    }

    private func setupUI() {
        contentView.backgroundColor = .white
        contentView.clipsToBounds = true

        contentView.addSubview(bookImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(authorLabel)
    }

    private func setupConstraints() {
        bookImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(12)
            $0.centerY.equalToSuperview()
            $0.width.equalTo(48)
            $0.height.equalTo(72)
        }

        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(bookImageView.snp.trailing).offset(12)
            $0.trailing.equalToSuperview().inset(12)
            $0.top.equalToSuperview().offset(12)
        }

        authorLabel.snp.makeConstraints {
            $0.leading.trailing.equalTo(titleLabel)
            $0.top.equalTo(titleLabel.snp.bottom).offset(4)
        }
    }
}

// MARK: - UIImageView Extension

extension UIImageView {
    func loadImage(from url: URL) {
        DispatchQueue.global().async {
            if let data = try? Data(contentsOf: url),
               let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.image = image
                }
            }
        }
    }
}
