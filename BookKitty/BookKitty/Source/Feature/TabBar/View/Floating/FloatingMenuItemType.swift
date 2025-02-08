//
//  FloatingMenuItemType.swift
//  BookKitty
//
//  Created by 전성규 on 1/31/25.
//

import DesignSystem
import Foundation
import UIKit

enum FloatingMenuItemType: String, CaseIterable {
    case addQuestion = "책냥이에게 질문하기"
    case addBook = "책 추가하기"

    // MARK: - Computed Properties

    // MARK: - Internal

    var iconName: String {
        switch self {
        case .addQuestion: "plus.bubble.fill"
        case .addBook: "video.fill.badge.plus"
        }
    }

    var iconColor: UIColor {
        switch self {
        case .addQuestion: Colors.brandMain
        case .addBook: Colors.brandSub
        }
    }
}
