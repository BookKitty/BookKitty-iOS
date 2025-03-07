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
    // MARK: - Properties

    // MARK: - Private

    private var isLoadingMore = false
    private var wasBottom = false

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
        $0.backgroundColor = .clear
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

    // MARK: - Lifecycle

    init(viewModel: MyLibraryViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "MyLibraryViewController"
    }

    // MARK: - Overridden Functions

    // MARK: - Internal

    override func bind() {
        let input = MyLibraryViewModel.Input(
            viewWillAppear: viewWillAppearRelay.asObservable(),
            bookTapped: bookTappedRelay.asObservable(),
            reachedScrollEnd: reachedScrollEndRelay.asObservable()
        )

        let output = viewModel.transform(input)

        output.bookList
            .drive(myLibraryCollectionView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)

        output.bookList
            .skip(1) // VM에 위치한 bookList(BehaviorRelay) 기본 빈 배열 무시
            .map { sectionModelList -> UIView? in
                if sectionModelList[0].items.isEmpty {
                    let containerView = UIView()
                    let emptyView = EmptyDataDescriptionView(with: .book)

                    containerView.addSubview(emptyView)
                    emptyView.snp.makeConstraints { $0.center.equalToSuperview() }

                    return containerView
                } else {
                    return nil // 아이템이 존재하면 backgroundView를 제거
                }
            }
            .drive(myLibraryCollectionView.rx.backgroundView)
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

extension MyLibraryViewController: UICollectionViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView.contentSize.height > scrollView.bounds.height,
              !isLoadingMore else {
            return
        }

        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let scrollViewHeight = scrollView.bounds.height
        let threshold: CGFloat = 50
        let isBottom = offsetY + scrollViewHeight + threshold > contentHeight

        if isBottom {
            if !wasBottom {
                wasBottom = true
                isLoadingMore = true
                reachedScrollEndRelay.accept(())
            }
        } else {
            wasBottom = false
        }
    }

    func scrollViewDidEndDragging(_: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            isLoadingMore = false
        }
    }

    func scrollViewDidEndDecelerating(_: UIScrollView) {
        isLoadingMore = false
    }
}

@available(iOS 17.0, *)
#Preview {
    let repository = MockBookRepository()
    let viewModel = MyLibraryViewModel(bookRepository: repository)

    return MyLibraryViewController(viewModel: viewModel)
}
