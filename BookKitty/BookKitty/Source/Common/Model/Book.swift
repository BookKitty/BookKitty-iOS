//
//  Book.swift
//  BookKitty
//
//  Created by 권승용 on 1/29/25.
//

import Foundation
import RxDataSources

struct Book: IdentifiableType, Hashable {
    // MARK: - Properties

    // MARK: - Internal

    let isbn: String
    let title: String
    let author: String
    let publisher: String
    let thumbnailUrl: URL?
    var isOwned: Bool
    let bookInfoLink: String
    let createdAt: Date
    let updatedAt: Date
    let description: String
    let price: String
    let pubDate: String

    // MARK: - Computed Properties

    var identity: String {
        isbn
    }

    // MARK: - Lifecycle

    init(
        isbn: String,
        title: String,
        author: String,
        publisher: String,
        thumbnailUrl: URL?,
        isOwned: Bool = false,
        bookInfoLink: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        description: String = "이 책을 추천합니다.",
        price: String = "가격 미정",
        pubDate: String = "출판일 알 수 없음"
    ) {
        self.isbn = isbn
        self.title = title
        self.author = author
        self.publisher = publisher
        self.thumbnailUrl = thumbnailUrl
        self.isOwned = isOwned
        self.bookInfoLink = bookInfoLink
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.description = description
        self.price = price
        self.pubDate = pubDate
    }
}
