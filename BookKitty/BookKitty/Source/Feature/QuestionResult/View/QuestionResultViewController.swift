//
//  QuestionResultViewController.swift
//  BookKitty
//
//  Created by 권승용 on 2/4/25.
//

import BookMatchCore
import DesignSystem
import RxCocoa
import RxDataSources
import RxRelay
import RxSwift
import SnapKit
import Then
import UIKit

final class QuestionResultViewController: BaseViewController {
    // MARK: - Properties

    // MARK: - Private

    private let bookSelectedRelay = PublishRelay<Book>()
    private let submitButtonTappedRelay = PublishRelay<Void>()

    private let scrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = false
        $0.showsHorizontalScrollIndicator = false
    }

    private let contentView = UIView()

    private let userQuestionHeadlineLabel = Headline3Label(weight: .extraBold).then {
        $0.text = "당신의 질문"
        $0.textColor = Colors.brandSub
    }

    private let userQuestionBodyLabel = UserQuestionView(questionText: "")

    private let recommendedBooksHeadlineLabel = TwoLineLabel(
        text1: "책냥이가 위 질문에 대해",
        text2: "다음의 책을 추천합니다."
    )

    private let recommendationHeadlineLabel = Headline3Label(weight: .extraBold).then {
        $0.text = "추천해요"
        $0.textColor = Colors.brandSub
    }

    private let recommendationBodyLabel = BodyLabel(weight: .regular)

    private let submitButton = RoundButton(title: "답변 확인을 완료합니다")

    private let viewModel: QuestionResultViewModel

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

    init(viewModel: QuestionResultViewModel) {
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
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        [
            userQuestionHeadlineLabel,
            userQuestionBodyLabel,
            recommendedBooksHeadlineLabel,
            recommendedBooksCollectionView,
            recommendationHeadlineLabel,
            recommendationBodyLabel,
            submitButton,
        ].forEach { contentView.addSubview($0) }
    }

    override func configureLayout() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentView.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.verticalEdges.equalToSuperview()
        }

        userQuestionHeadlineLabel.snp.makeConstraints { make in
            make.top.equalTo(contentView.safeAreaLayoutGuide.snp.top).offset(Vars.spacing24)
            make.leading.equalTo(contentView.safeAreaLayoutGuide.snp.leading).offset(Vars.spacing24)
        }

        userQuestionBodyLabel.snp.makeConstraints { make in
            make.top.equalTo(userQuestionHeadlineLabel.snp.bottom).offset(Vars.spacing12)
            make.horizontalEdges.equalTo(contentView.safeAreaLayoutGuide).inset(Vars.spacing24)
        }

        recommendedBooksHeadlineLabel.snp.makeConstraints { make in
            make.top.equalTo(userQuestionBodyLabel.snp.bottom).offset(Vars.spacing48)
            make.horizontalEdges.equalTo(contentView.safeAreaLayoutGuide).inset(Vars.spacing24)
        }

        recommendedBooksCollectionView.snp.makeConstraints { make in
            make.top.equalTo(recommendedBooksHeadlineLabel.snp.bottom).offset(Vars.spacing24)
            make.horizontalEdges.equalTo(contentView.safeAreaLayoutGuide)
            make.height.greaterThanOrEqualTo(448)
        }

        recommendationHeadlineLabel.snp.makeConstraints { make in
            make.top.equalTo(recommendedBooksCollectionView.snp.bottom).offset(Vars.spacing72)
            make.horizontalEdges.equalTo(contentView.safeAreaLayoutGuide).inset(Vars.spacing24)
        }

        recommendationBodyLabel.snp.makeConstraints { make in
            make.top.equalTo(recommendationHeadlineLabel.snp.bottom).offset(Vars.spacing12)
            make.horizontalEdges.equalTo(contentView.safeAreaLayoutGuide).inset(Vars.spacing24)
        }

        submitButton.snp.makeConstraints { make in
            make.top.equalTo(recommendationBodyLabel.snp.bottom).offset(Vars.spacing48)
            make.horizontalEdges.equalTo(contentView.safeAreaLayoutGuide).inset(Vars.spacing24)
            make.bottom.equalToSuperview().inset(Vars.spacing16)
        }
    }

    override func bind() {
        let input = QuestionResultViewModel.Input(
            viewDidLoad: viewDidLoadRelay.asObservable(),
            bookSelected: bookSelectedRelay.asObservable(),
            submitButtonTapped: submitButtonTappedRelay.asObservable()
        )

        let output = viewModel.transform(input)

        output.userQuestion
            .drive(onNext: { [weak self] question in
                self?.userQuestionBodyLabel.setQuestionText(question)
            })
            .disposed(by: disposeBag)

        output.recommendedBooks
            .drive(recommendedBooksCollectionView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)

        output.recommendationReason
            .drive(onNext: { [weak self] reason in
                self?.recommendationBodyLabel.text = reason
            })
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
                return books[indexPath.item]
            }
            .bind(to: bookSelectedRelay)
            .disposed(by: disposeBag)

        submitButton.rx.tap
            .bind(to: submitButtonTappedRelay)
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
    let viewModel = QuestionResultViewModel(
        userQuestion: "샘플 사용자 질문 입니다. 샘플 사용자 질문 입니다.",
        recommendationService: MockRecommendationService(),
        bookRepository: MockBookRepository(),
        questionHistoryRepository: MockQuestionHistoryRepository()
    )
    return QuestionResultViewController(viewModel: viewModel)
}
