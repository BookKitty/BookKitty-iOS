//
//  MyLibraryViewController.swift
//  BookKitty
//  P-003
//
//  Created by 전성규 on 1/27/25.
//

import DesignSystem
import RxCocoa
import RxDataSources
import RxSwift
import SnapKit
import Then
import UIKit

final class MyLibraryViewController: BaseViewController {
    // MARK: Lifecycle

    init(viewModel: MyLibraryViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    override func bind() {
        let input = MyLibraryViewModel.Input(
            viewDidLoad: viewDidLoadRelay.asObservable(),
            bookTapped: bookTappedRelay.asObservable(),
            reachedScrollEnd: reachedScrollEndRelay.asObservable()
        )

        let output = viewModel.transform(input)

        output.bookList
            .drive(myLibraryCollectionView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)

        myLibraryCollectionView.rx.itemSelected
            .withLatestFrom(output.bookList) { indexPath, sectionOfBooks in
                let books = sectionOfBooks[0].items
                return books[indexPath.item]
            }
            .bind(to: bookTappedRelay)
            .disposed(by: disposeBag)
    }

    override func configureHierarchy() {
        [
            myLibraryHeadlineLabel,
            myLibraryCollectionView,
        ].forEach { view.addSubview($0) }
    }

    override func configureLayout() {
        myLibraryHeadlineLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(Vars.spacing20)
            make.horizontalEdges.equalTo(view.safeAreaLayoutGuide).inset(Vars.spacing24)
        }

        myLibraryCollectionView.snp.makeConstraints { make in
            make.top.equalTo(myLibraryHeadlineLabel.snp.bottom).offset(Vars.spacing20)
            make.horizontalEdges.equalTo(view.safeAreaLayoutGuide)
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }
    }

    // MARK: Private

    private let bookTappedRelay = PublishRelay<Book>()
    private let reachedScrollEndRelay = PublishRelay<Void>()

    private let viewModel: MyLibraryViewModel

    private let myLibraryHeadlineLabel = Headline1Label(weight: .extraBold).then {
        $0.text = "나의 책장"
    }

    private lazy var myLibraryCollectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: makeCompositionalLayout()
    ).then {
        $0.delegate = self
        $0.register(
            MyLibraryCollectionViewCell.self,
            forCellWithReuseIdentifier: MyLibraryCollectionViewCell.reuseIdentifier
        )
    }

    private let dataSource = RxCollectionViewSectionedAnimatedDataSource<SectionOfBook>(
        configureCell: { _, collectionView, indexPath, item in
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: MyLibraryCollectionViewCell.reuseIdentifier,
                for: indexPath
            ) as? MyLibraryCollectionViewCell else {
                return MyLibraryCollectionViewCell()
            }

            cell.configureCell(imageUrl: item.thumbnailUrl)

            return cell
        }
    )
}

extension MyLibraryViewController {
    func makeCompositionalLayout() -> UICollectionViewCompositionalLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(0.3),
            heightDimension: .fractionalHeight(1)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .absolute(150)
        )
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            repeatingSubitem: item,
            count: 3
        )
        group.interItemSpacing = .flexible(Vars.spacing4)

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(
            top: Vars.spacing20,
            leading: Vars.spacing24,
            bottom: 0,
            trailing: Vars.spacing24
        )
        section.interGroupSpacing = Vars.spacing32

        return UICollectionViewCompositionalLayout(section: section)
    }
}

// TODO: 고도화 필요
extension MyLibraryViewController: UICollectionViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView.contentSize.height > scrollView.bounds.height else {
            return
        }

        if scrollView.contentOffset.y > scrollView.contentSize.height - scrollView.bounds.height {
            reachedScrollEndRelay.accept(())
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    let repository = MockBookRepository()
    let viewModel = MyLibraryViewModel(bookRepository: repository)

    return MyLibraryViewController(viewModel: viewModel)
}
