//
//  TabBarView.swift
//  BookKitty
//
//  Created by 전성규 on 1/29/25.
//

import RxCocoa
import RxSwift
import Then
import UIKit

/// 커스텀 탭 바 뷰
/// - `TabBarItem`을 **수평**으로 배치하고, 선택된 인덱스를 Rx로 전달
final class TabBarView: UIStackView {
    // MARK: Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupTabBarItems()
        configureUI()
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    /// 선택된 탭의 인덱스를 방출하는 Relay
    private(set) var selectedIndex = PublishRelay<Int>()

    // MARK: Private

    private let disposeBag = DisposeBag()

    /// `TabBarItem`을 생성하고 `selectedIndex`와 바인딩
    private func setupTabBarItems() {
        for type in TabBarItemType.allCases {
            let item = TabBarItem(with: type)
                .then {
                    $0.rx.selectedTabIndex
                        .bind(to: selectedIndex)
                        .disposed(by: disposeBag)
                }

            addArrangedSubview(item)
        }
    }

    private func configureUI() {
        axis = .horizontal
        distribution = .fillEqually

        layer.cornerRadius = 24.0
        clipsToBounds = true

        backgroundColor = UIColor(red: 0.945, green: 0.945, blue: 0.961, alpha: 1.0)
    }
}
