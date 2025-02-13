// ReviewAddBookViewController.swift

import BookMatchKit
import DesignSystem
import RxCocoa
import RxDataSources
import RxSwift
import SnapKit
import Then
import UIKit

final class ReviewAddBookViewController: BaseViewController {
    // MARK: - Properties

    private let viewModel: ReviewAddBookViewModel
    private let deleteBookSubject = PublishSubject<Int>()
    private let manualTitleSubject = PublishSubject<String>()
    private var addedBookTitles = Set<String>()
    private let addBookButton = TextButton(title: "+ 책 추가하기")
    private let confirmButton = RoundButton(title: "추가 완료")

    private let manualAddPopup = TitleInputPopupView()
    private let navigationBar = CustomNavigationBar()
    private let dimmingView = DimmingView()

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

    // MARK: - ViewModel Binding

    private let capturedImageRelay = PublishRelay<UIImage>()

    // MARK: - Lifecycle

    init(viewModel: ReviewAddBookViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        bindViewModel()
        bindPopup() // 추가
    }

    // MARK: - Functions

    // MARK: - OCR 결과 반영 (수정됨)

    func appendBook(_ book: Book) {
        guard !addedBookTitles.contains(book.title) else {
            return
        }
        addedBookTitles.insert(book.title)
        viewModel.appendBook(book)
    }

    func appendOCRResult(_ recognizedText: String) {
        guard !recognizedText.isEmpty else {
            return
        }

        let book = Book(
            isbn: "",
            title: recognizedText,
            author: "알 수 없음",
            publisher: "알 수 없음",
            thumbnailUrl: nil
        )

        appendBook(book)
    }

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

    private func bindViewModel() {
        let input = ReviewAddBookViewModel.Input(
            addBookWithTitleTapTrigger: manualTitleSubject.asObservable(),
            deleteBookTapTrigger: deleteBookSubject.asObservable(),
            confirmButtonTapTrigger: confirmButton.rx.tap.asObservable(),
            leftBarButtonTapTrigger: navigationBar.backButtonTapped.asObservable(),
            capturedImage: capturedImageRelay.asObservable()
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

//        output.bookList
//            .map { [SectionModel(model: "Books", items: $0)] }
//            .bind(to: collectionView.rx.items(dataSource: dataSource))
//            .disposed(by: disposeBag)

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

    private func bindPopup() {
        addBookButton.rx.tap
            .observe(on: MainScheduler.instance)
            .withUnretained(self)
            .bind(onNext: { owner, _ in
                let manualAddPopup = owner.manualAddPopup
                owner.dimmingView.isVisible.accept(true)

                if owner.view.subviews.contains(where: { $0 is TitleInputPopupView }) {
                    manualAddPopup.isHidden = false
                } else {
                    owner.view.addSubview(manualAddPopup)
                    manualAddPopup.snp.makeConstraints {
                        $0.horizontalEdges.equalToSuperview().inset(Vars.paddingReg)
                        $0.centerY.equalToSuperview()
                    }
                }
            }).disposed(by: disposeBag)

        manualAddPopup.confirmButton.rx.tap
            .withLatestFrom(manualAddPopup.bookTitleInput.rx.text.orEmpty)
            .filter { !$0.isEmpty }
            .do(onNext: { [weak self] _ in
                self?.dimmingView.isVisible.accept(false)
                self?.manualAddPopup.bookTitleInput.text = "" // 입력 필드 초기화
            })
            .bind(to: manualTitleSubject)
            .disposed(by: disposeBag)

        manualAddPopup.cancelButton.rx.tap
            .map { false }
            .bind(to: dimmingView.isVisible)
            .disposed(by: disposeBag)

        dimmingView.isVisible
            .skip(1)
            .filter { !$0 }
            .observe(on: MainScheduler.instance)
            .withUnretained(self)
            .bind(onNext: { owner, _ in
                owner.manualAddPopup.isHidden = true
            }).disposed(by: disposeBag)
    }
}

// MARK: - BookCell

final class BookCell: UICollectionViewCell {
    // MARK: - Static Properties

    static let identifier = "BookCell"

    // MARK: - Properties

    private let bookImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.layer.cornerRadius = 4
        $0.clipsToBounds = true
        $0.backgroundColor = UIColor.lightGray.withAlphaComponent(0.05)
    }

    private let titleLabel = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        $0.textColor = .black
        $0.numberOfLines = 2
        $0.textAlignment = .left
        $0.adjustsFontSizeToFitWidth = true
        $0.minimumScaleFactor = 0.9
    }

    private let authorLabel = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        $0.textColor = .darkGray
        $0.textAlignment = .left
        $0.adjustsFontSizeToFitWidth = true
        $0.minimumScaleFactor = 0.9
    }

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

    // MARK: - Functions

    func configure(with book: Book) {
        titleLabel.text = book.title
        authorLabel.text = "\(book.author) 지음"

        if let imageUrl = book.thumbnailUrl {
            bookImageView.loadImage(from: imageUrl)
        } else {
            bookImageView.image = UIImage(named: "default_book")
        }
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

@available(iOS 17.0, *)
#Preview {
    let bookMatchKit: BookMatchKit? = nil // ✅ `nil` 가능하게 설정 (OCR 비활성화)

    ReviewAddBookViewController(
        viewModel: ReviewAddBookViewModel(bookMatchKit: bookMatchKit!)
    )
}
