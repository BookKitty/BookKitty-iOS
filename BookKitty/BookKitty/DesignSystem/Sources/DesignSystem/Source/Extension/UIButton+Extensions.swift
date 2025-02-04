//
//  UIButton+Extensions.swift
//  DesignSystem
//
//  Created by MaxBook on 2/1/25.
//

import UIKit

// MARK: - Button Action Assignment

extension UIButton {
    /// 부모로부터 액션을 할당받아 버튼의 터치 동작과 연결.
    /// - Parameter action: 동작을 수행하는 클로저
    @available(iOS 14.0, *)
    public func applyButtonAction(action: @escaping () -> Void) {
        let actionHandler = UIAction { _ in
            action()
        }

        addAction(actionHandler, for: .touchUpInside)
    }

    /// 부모로부터 비동기 액션을 할당받아 버튼의 터치 동작과 연결.
    /// - Parameter action: 비동기 동작을 수행하는 클로저
    @available(iOS 14.0, *)
    public func applyButtonAsyncAction(action: @escaping () async -> Void) {
        let actionHandler = UIAction { _ in
            Task {
                await action()
            }
        }

        addAction(actionHandler, for: .touchUpInside)
    }
}
