//
//  FloatingMenuItem.swift
//  BookKitty
//
//  Created by 전성규 on 1/31/25.
//

import RxSwift
import UIKit

final class FloatingMenuItem: UIButton {
    // MARK: Lifecycle

    init(with type: FloatingMenuItemType) {
        self.type = type
        super.init(frame: .zero)

        configureUI()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    private(set) var type: FloatingMenuItemType

    // MARK: Private

    private func configureUI() {
        setTitle(type.rawValue, for: .normal)
        setTitleColor(.black, for: .normal)
    }
}

extension Reactive where Base: FloatingMenuItem {
    var selectedItem: Observable<FloatingMenuItemType> {
        base.rx.tap
            .map { base.type }
    }
}
