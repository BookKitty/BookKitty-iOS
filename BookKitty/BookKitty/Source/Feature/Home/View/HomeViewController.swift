//
//  HomeViewController.swift
//  BookKitty
//
//  Created by 권승용 on 1/23/25.
//

import DesignSystem
import RxCocoa
import RxDataSources
import RxRelay
import RxSwift
import SnapKit
import Then
import UIKit

class HomeViewController: BaseViewController {
    // MARK: - Properties

    // MARK: - Private

    private let bookSelectedRelay = PublishRelay<Book>()

    private let viewModel: HomeViewModel

    private let titleLabel = Headline3Label(weight: .extraBold).then {
        $0.text = "책냥이가 아래 책들을 추천합니다."
        $0.textColor = Colors.fontMain
    }

    private let copyrightLabel = CaptionLabel().then {
        $0.text = "Developed by 권승용, 김형석, 반성준, 임성수, 전상규"
        $0.textColor = Colors.fontSub1
        $0.textAlignment = .center
    }

    private lazy var recommendedBooksCollectionView: UICollectionView = {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: makeCollectionViewLayout()
        )
        collectionView.backgroundColor = Colors.brandSub30
        collectionView.register(
            RecommendedBookCell.self,
            forCellWithReuseIdentifier: RecommendedBookCell.reuseIdentifier
        )
        return collectionView
    }()

    private let dataSource = RxCollectionViewSectionedReloadDataSource<SectionOfBook>(
        configureCell: { _, collectionView, indexPath, item in
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: RecommendedBookCell.reuseIdentifier,
                for: indexPath
            ) as? RecommendedBookCell else {
                return RecommendedBookCell(frame: .zero)
            }

            cell.configureCell(
                bookTitle: item.title,
                bookAuthor: item.author,
                imageUrl: item.thumbnailUrl?.absoluteString ?? "",
                isOwned: item.isOwned
            )

            return cell
        }
    )

    // MARK: - Lifecycle

    init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Overridden Functions

    // MARK: - Internal

    override func configureHierarchy() {
        [titleLabel, recommendedBooksCollectionView, copyrightLabel].forEach { view.addSubview($0) }
    }

    override func configureLayout() {
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(Vars.spacing48)
            make.horizontalEdges.equalTo(view.safeAreaLayoutGuide).inset(Vars.spacing24)
        }

        recommendedBooksCollectionView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(Vars.spacing24)
            make.horizontalEdges.equalTo(view.safeAreaLayoutGuide)
            make.height.greaterThanOrEqualTo(448)
        }

        copyrightLabel.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-Vars.spacing16)
            make.horizontalEdges.equalTo(view.safeAreaLayoutGuide).inset(Vars.spacing24)
        }
    }

    override func bind() {
        let input = HomeViewModel.Input(
            viewDidLoad: viewDidLoadRelay.asObservable(),
            bookSelected: bookSelectedRelay.asObservable()
        )

        let output = viewModel.transform(input)

        output.recommendedBooks
            .drive(recommendedBooksCollectionView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)

        output.error
            .withUnretained(self)
            .subscribe(onNext: { error in
                print("Error occurred : \(error)")
            })
            .disposed(by: disposeBag)

        recommendedBooksCollectionView.rx.itemSelected
            .withLatestFrom(output.recommendedBooks) { indexPath, sectionOfBooks in
                let books = sectionOfBooks[0].items
                print("gek")
                return books[indexPath.item]
            }
            .bind(to: bookSelectedRelay)
            .disposed(by: disposeBag)
    }

    // MARK: - Functions

    private func makeCollectionViewLayout() -> UICollectionViewCompositionalLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .fractionalHeight(1)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .absolute(240),
            heightDimension: .absolute(352)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = Vars.spacing20
        section.contentInsets = .init(
            top: Vars.spacing48,
            leading: Vars.spacing24,
            bottom: Vars.spacing48,
            trailing: Vars.spacing24
        )
        section.orthogonalScrollingBehavior = .groupPaging

        return UICollectionViewCompositionalLayout(section: section)
    }
}

@available(iOS 17.0, *)
#Preview {
    HomeViewController(viewModel: HomeViewModel(bookRepository: MockBookRepository()))
}
