//
//  AddBookByTitleViewController.swift
//  BookKitty
//
//  Created by 권승용 on 2/17/25.
//

import DesignSystem
import RxCocoa
import RxSwift
import SnapKit
import Then
import UIKit

private enum Section {
    case main
}

final class AddBookByTitleViewController: BaseViewController {
    // MARK: - Properties

    private let navigationBar = CustomNavigationBar()
    private lazy var searchBar = CustomSearchBar().then {
        $0.delegate = self
    }

    private lazy var collectionview = UICollectionView(frame: .zero, collectionViewLayout: layout)
        .then {
            $0.backgroundColor = Colors.background0
        }

    private let emptyResultLabel = Headline3Label().then {
        $0.text = "검색 결과가 없습니다."
        $0.isHidden = true
    }

    private let layout: UICollectionViewCompositionalLayout = {
        var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
        configuration.backgroundColor = Colors.background0
        return UICollectionViewCompositionalLayout.list(using: configuration)
    }()

    private let registration = UICollectionView
        .CellRegistration<AddBookByTitleCell, Book> { cell, _, model in
            cell.configureCell(
                imageLink: model.thumbnailUrl?.absoluteString ?? "",
                bookTitle: model.title,
                author: model.author
            )
        }

    private var dataSource: UICollectionViewDiffableDataSource<Section, Book>!

    private let viewModel: AddBookByTitleViewModel
    private let searchResultRelay = PublishRelay<String>()
    private let bookSelectionRelay = PublishRelay<Book>()

    // MARK: - Lifecycle

    init(viewModel: AddBookByTitleViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        configureDelegate()
        configureDataSource()
        super.viewDidLoad()
        addTapGestureToCollectionView()
        makeSearchBarFirstResponder()
    }

    // MARK: - Overridden Functions

    override func configureHierarchy() {
        [
            navigationBar,
            searchBar,
            collectionview,
            emptyResultLabel,
        ].forEach { view.addSubview($0) }
    }

    override func configureLayout() {
        navigationBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.horizontalEdges.equalTo(view.safeAreaLayoutGuide)
            make.height.equalTo(44) // TODO: navigationbar height 어떻게?
        }

        searchBar.snp.makeConstraints { make in
            make.top.equalTo(navigationBar.snp.bottom).offset(Vars.spacing24)
            make.horizontalEdges.equalToSuperview().inset(Vars.spacing24)
        }

        collectionview.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom).offset(Vars.spacing24)
            make.horizontalEdges.equalToSuperview().inset(Vars.spacing24)
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        emptyResultLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    override func bind() {
        let input = AddBookByTitleViewModel.Input(
            backButtonTapped: navigationBar.backButtonTapped.asObservable(),
            addBookButtonTapped: bookSelectionRelay.asObservable(),
            searchResult: searchResultRelay.asObservable()
        )

        let output = viewModel.transform(input)

        output.books
            .skip(1)
            .drive(onNext: { [weak self] books in
                self?.updateEmptyResultLabelVisibility(for: books)
                self?.configureSnapshot(with: books)
            })
            .disposed(by: disposeBag)
    }

    override func touchesBegan(_: Set<UITouch>, with _: UIEvent?) {
        view.endEditing(true)
    }

    // MARK: - Functions

    private func addTapGestureToCollectionView() {
        let singleTapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(keyboardDown)
        )
        singleTapGestureRecognizer.numberOfTapsRequired = 1
        singleTapGestureRecognizer.isEnabled = true
        singleTapGestureRecognizer.cancelsTouchesInView = false
        collectionview.addGestureRecognizer(singleTapGestureRecognizer)
    }

    private func configureDelegate() {
        searchBar.delegate = self
        collectionview.delegate = self
    }

    private func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<
            Section,
            Book
        >(collectionView: collectionview) { collectionView, indexPath, item in
            collectionView.dequeueConfiguredReusableCell(
                using: self.registration,
                for: indexPath,
                item: item
            )
        }
    }

    private func configureSnapshot(with items: [Book]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Book>()
        snapshot.appendSections([.main])
        snapshot.appendItems(items, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    private func updateEmptyResultLabelVisibility(for books: [Book]) {
        emptyResultLabel.isHidden = !books.isEmpty
    }

    private func makeSearchBarFirstResponder() {
        _ = searchBar.becomeFirstResponder()
    }
}

extension AddBookByTitleViewController {
    @objc
    private func keyboardDown() {
        view.endEditing(true)
    }
}

extension AddBookByTitleViewController: CustomSearchBarDelegate {
    func searchBarSearchButtonClicked(_ bar: CustomSearchBar) {
        let searchText = bar.searchText ?? ""
        searchResultRelay.accept(searchText)
    }
}

extension AddBookByTitleViewController: UICollectionViewDelegate {
    func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let selectedBook = dataSource.itemIdentifier(for: indexPath) else {
            BookKittyLogger.error("선택된 Book 존재하지 않음")
            return
        }

        let vc = AddBookConfirmViewController { [weak self] addBook in
            if addBook {
                self?.bookSelectionRelay.accept(selectedBook)
            }
        }
        vc.present(by: self, with: selectedBook)
    }
}

@available(iOS 17.0, *)
#Preview {
    AddBookByTitleViewController(
        viewModel: AddBookByTitleViewModel(
            bookRepository: MockBookRepository(),
            bookOcrKit: MockBookOCRKit()
        )
    )
}
