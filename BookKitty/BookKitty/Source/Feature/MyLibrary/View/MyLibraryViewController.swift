//
//  MyLibraryViewController.swift
//  BookKitty
//  P-003
//
//  Created by 전성규 on 1/27/25.
//

import RxCocoa
import RxSwift
import SnapKit
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
            // TODO: 컬렉션뷰 셀 탭 시 탭 된 셀의 Book 정보 방출하는 relay에 연결
            bookTapped: Observable<Book>.create { _ in
                Disposables.create()
            },
            // TODO: 컬렉션뷰 하단 스크롤 이벤트 연결
            reachedScrollEnd: Observable<Void>.create { _ in
                Disposables.create()
            }
        )

        let output = viewModel.transform(input)

        output.bookList
            .drive { books in
                print(books)
            }
            .disposed(by: disposeBag)
    }

    override func configureHierarchy() {
        [testLabel, testButton].forEach { view.addSubview($0) }
    }

    override func configureLayout() {
        testLabel.snp.makeConstraints { $0.center.equalToSuperview() }

        testButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(testLabel.snp.bottom).offset(20.0)
            $0.width.height.equalTo(150.0)
        }
    }

    // MARK: Private

    private let viewModel: MyLibraryViewModel

    private let testLabel: UILabel = {
        let label = UILabel()
        label.text = "P-003"
        label.font = .systemFont(ofSize: 30.0, weight: .bold)

        return label
    }()

    private let testButton: UIButton = {
        let button = UIButton()
        button.setTitle("Book Thumbnail", for: .normal)
        button.backgroundColor = .tintColor

        return button
    }()
}

@available(iOS 17.0, *)
#Preview {
    let repository = MockBookRepository()
    let viewModel = MyLibraryViewModel(bookRepository: repository)

    return MyLibraryViewController(viewModel: viewModel)
}
