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
    private let searchBar = UISearchBar().then {
        $0.searchBarStyle = .minimal
    }

    private lazy var collectionview = UICollectionView(frame: .zero, collectionViewLayout: layout)

    private let layout: UICollectionViewCompositionalLayout = {
        var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
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
    }

    // MARK: - Overridden Functions

    override func configureHierarchy() {
        [
            navigationBar,
            searchBar,
            collectionview,
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
    }

    override func bind() {
        let input = AddBookByTitleViewModel.Input(
            backButtonTapped: navigationBar.backButtonTapped.asObservable(),
            searchResult: searchResultRelay.asObservable()
        )

        let output = viewModel.transform(input)

        output.books
            .drive(onNext: { [weak self] books in
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
}

extension AddBookByTitleViewController {
    @objc
    private func keyboardDown() {
        view.endEditing(true)
    }
}

extension AddBookByTitleViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ bar: UISearchBar) {
        let searchText = bar.text ?? ""
        searchResultRelay.accept(searchText)
    }
}

@available(iOS 17.0, *)
#Preview {
    AddBookByTitleViewController(
        viewModel: AddBookByTitleViewModel(bookOcrKit: MockBookOCRKit())
    )
}
