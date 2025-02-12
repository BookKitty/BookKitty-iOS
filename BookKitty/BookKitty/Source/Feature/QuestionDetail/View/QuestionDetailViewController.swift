//
//  QuestionDetailViewController.swift
//  BookKitty
//  P-007
//
//  Created by 전성규 on 1/26/25.
//

import DesignSystem
import RxCocoa
import RxDataSources
import RxSwift
import SnapKit
import Then
import UIKit

final class QuestionDetailViewController: BaseViewController {
    // MARK: - Properties

    // MARK: - Private

    private let bookTappedRelay = PublishRelay<Book>()

    private let viewModel: QuestionDetailViewModel
    private let deleteButtonTappedRelay = PublishRelay<Void>()

    private let navigationBar = CustomNavigationBar().then {
        $0.setupRightBarButton(with: .delete)
    }

    private let scrollView = UIScrollView().then {
        $0.isScrollEnabled = true
        $0.showsVerticalScrollIndicator = false
        $0.showsHorizontalScrollIndicator = false
    }

    private let contentView = UIView()

    private let dateCaptionLabel = CaptionLabel()

    private let userQuestionHeadlineLabel = Headline3Label(weight: .extraBold).then {
        $0.textColor = Colors.brandSub
    }

    private let userQuestionBodyLabel = UserQuestionView(questionText: "")

    private let recommendationReasonHeadlineLabel = Headline3Label(weight: .extraBold).then {
        $0.text = "추천해요"
        $0.textColor = Colors.brandSub
    }

    private let recommendationReasonBodyLabel = BodyLabel()

    private lazy var recommendedBooksCollectionView: UICollectionView = {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: makeCollectionViewLayout()
        )
        collectionView.backgroundColor = Colors.brandMain30
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

    init(viewModel: QuestionDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        recommendedBooksCollectionView.layoutIfNeeded()
        recommendedBooksCollectionView.snp.makeConstraints { make in
            make.height
                .equalTo(
                    recommendedBooksCollectionView.collectionViewLayout
                        .collectionViewContentSize.height
                )
        }
        // content hugging, compression resistance priority도 괜찮은 것 같음
    }

    // MARK: - Overridden Functions

    // MARK: - Internal

    override func bind() {
        let input = QuestionDetailViewModel.Input(
            viewDidLoad: viewDidLoadRelay.asObservable(),
            viewWillAppear: viewWillAppearRelay.asObservable(),
            deleteButtonTapped: navigationBar.rightButtonTapped.asObservable(),
            backButtonTapped: navigationBar.backButtonTapped.asObservable(),
            bookTapped: bookTappedRelay.asObservable()
        )

        let output = viewModel.transform(input)

        output.questionDate
            .drive(onNext: { [weak self] date in
                self?.dateCaptionLabel.text = date
                self?.userQuestionHeadlineLabel.text = "\(date), 당신의 질문"
            })
            .disposed(by: disposeBag)

        output.userQuestion
            .drive(onNext: { [weak self] userQuestion in
                self?.userQuestionBodyLabel.setQuestionText(userQuestion)
            })
            .disposed(by: disposeBag)

        output.recommendationReason
            .drive(onNext: { [weak self] reason in
                self?.recommendationReasonBodyLabel.text = reason
            })
            .disposed(by: disposeBag)

        output.recommendedBooks
            .drive(recommendedBooksCollectionView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)

        recommendedBooksCollectionView.rx.itemSelected
            .withLatestFrom(output.recommendedBooks) { indexPath, sectionOfBooks in
                let books = sectionOfBooks[0].items
                return books[indexPath.item]
            }
            .bind(to: bookTappedRelay)
            .disposed(by: disposeBag)
    }

    override func configureNavItem() {
        let rightBarButtonItem = UIBarButtonItem(
            title: "삭제",
            style: .plain,
            target: self,
            action: #selector(deleteButtonTapped)
        )
        navigationItem.setRightBarButton(rightBarButtonItem, animated: true)
    }

    override func configureHierarchy() {
        [navigationBar, scrollView].forEach { view.addSubview($0) }
        scrollView.addSubview(contentView)
        [
            dateCaptionLabel,
            userQuestionHeadlineLabel,
            userQuestionBodyLabel,
            recommendationReasonHeadlineLabel,
            recommendationReasonBodyLabel,
            recommendedBooksCollectionView,
        ].forEach { contentView.addSubview($0) }
    }

    override func configureLayout() {
        navigationBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.horizontalEdges.equalToSuperview()
            make.height.equalTo(Vars.viewSizeReg)
        }

        scrollView.snp.makeConstraints { make in
            make.top.equalTo(navigationBar.snp.bottom)
            make.horizontalEdges.bottom.equalToSuperview()
        }

        contentView.snp.makeConstraints { make in
            make.width.equalToSuperview() // edge가 아닌 width를 맞추는게 뽀인뜨
            make.verticalEdges.equalToSuperview()
        }

        dateCaptionLabel.snp.makeConstraints { make in
            make.top.equalTo(contentView.safeAreaLayoutGuide.snp.top).offset(Vars.spacing24)
            make.horizontalEdges.equalTo(contentView.safeAreaLayoutGuide).inset(Vars.spacing24)
        }

        userQuestionHeadlineLabel.snp.makeConstraints { make in
            make.top.equalTo(dateCaptionLabel.snp.bottom).offset(Vars.spacing4)
            make.horizontalEdges.equalTo(contentView.safeAreaLayoutGuide).inset(Vars.spacing24)
        }

        userQuestionBodyLabel.snp.makeConstraints { make in
            make.top.equalTo(userQuestionHeadlineLabel.snp.bottom).offset(Vars.spacing12)
            make.horizontalEdges.equalTo(contentView.safeAreaLayoutGuide).inset(Vars.spacing24)
        }

        recommendationReasonHeadlineLabel.snp.makeConstraints { make in
            make.top.equalTo(userQuestionBodyLabel.snp.bottom).offset(Vars.spacing48)
            make.horizontalEdges.equalTo(contentView.safeAreaLayoutGuide).inset(Vars.spacing24)
        }

        recommendationReasonBodyLabel.snp.makeConstraints { make in
            make.top.equalTo(recommendationReasonHeadlineLabel.snp.bottom).offset(Vars.spacing8)
            make.horizontalEdges.equalTo(contentView.safeAreaLayoutGuide).inset(Vars.spacing24)
        }

        recommendedBooksCollectionView.snp.makeConstraints { make in
            make.top.equalTo(recommendationReasonBodyLabel.snp.bottom).offset(Vars.spacing72)
            make.horizontalEdges.equalTo(contentView.safeAreaLayoutGuide)
            make.height.greaterThanOrEqualTo(400)
            make.bottom.equalTo(contentView)
        }
    }

    // MARK: - Functions

    @objc
    private func deleteButtonTapped() {
        deleteButtonTappedRelay.accept(())
    }
}

extension QuestionDetailViewController {
    private func makeCollectionViewLayout() -> UICollectionViewCompositionalLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .fractionalHeight(1)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .absolute(240),
            heightDimension: .estimated(352)
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
    QuestionDetailViewController(
        viewModel: QuestionDetailViewModel(
            questionAnswer: QuestionAnswer(
                createdAt: Date(),
                userQuestion: "유저 질문이에요",
                gptAnswer: "지피티 응답이에요",
                recommendedBooks: MockBookRepository().mockBookList
            ),
            questionHistoryRepository: MockQuestionHistoryRepository()
        )
    )
}
