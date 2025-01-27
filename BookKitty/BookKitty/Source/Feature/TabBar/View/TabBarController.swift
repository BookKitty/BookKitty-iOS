//
//  TabBarController.swift
//  BookKitty
//
//  Created by 전성규 on 1/26/25.
//

import RxCocoa
import RxSwift
import SnapKit
import UIKit

final class TabBarController: UITabBarController {
    // MARK: Lifecycle

    init(viewModel: TabBarViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    override func viewDidLoad() {
        super.viewDidLoad()

        bind()
        configureHierarchy()
        configureLayout()
    }

    // MARK: Private

    private let floatingButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "plus"), for: .normal)
        button.tintColor = .black
        button.backgroundColor = .orange
        button.layer.cornerRadius = 50.0 / 2

        return button
    }()

    private let testButton01: UIButton = {
        let button = UIButton()
        button.setTitle("책 추가", for: .normal)
        button.backgroundColor = .orange

        return button
    }()

    private var viewModel: TabBarViewModel

    private let testButton02: UIButton = {
        let button = UIButton()
        button.setTitle("질문하기", for: .normal)
        button.backgroundColor = .orange

        return button
    }()

    private func bind() {}

    private func configureHierarchy() {
        [floatingButton, testButton01, testButton02].forEach { view.addSubview($0) }
    }

    private func configureLayout() {
        floatingButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(20.0)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(tabBar.bounds.height + 20.0)
            $0.width.equalTo(100.0)
            $0.height.equalTo(50.0)
        }

        testButton01.snp.makeConstraints {
            $0.trailing.equalTo(floatingButton)
            $0.bottom.equalTo(floatingButton.snp.top).offset(-20.0)
            $0.width.equalTo(100.0)
        }

        testButton02.snp.makeConstraints {
            $0.trailing.equalTo(floatingButton)
            $0.bottom.equalTo(testButton01.snp.top).offset(-20.0)
            $0.width.equalTo(100.0)
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    let viewModel = TabBarViewModel()
    return TabBarController(viewModel: viewModel)
}
