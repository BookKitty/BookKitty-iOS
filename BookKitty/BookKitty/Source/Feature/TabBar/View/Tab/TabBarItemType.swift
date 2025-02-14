//
//  TabBarItemType.swift
//  BookKitty
//
//  Created by 전성규 on 1/29/25.
//

import UIKit

enum TabBarItemType: String, CaseIterable {
    case home = "Home"
    case qna = "Q&A"
    case library = "Library"

    // MARK: - Computed Properties

    // MARK: - Internal

    var index: Int {
        switch self {
        case .home: 0
        case .qna: 1
        case .library: 2
        }
    }

    var iconName: String {
        switch self {
        case .home: "house.fill"
        case .qna: "questionmark.bubble.fill"
        case .library: "books.vertical.fill"
        }
    }
}
