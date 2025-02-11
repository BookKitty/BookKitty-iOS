//
//  MockRecommendationService.swift
//  BookKitty
//
//  Created by 권승용 on 2/5/25.
//

import BookRecommendationKit
import BookMatchCore
import Foundation
import RxSwift
import UIKit

/// Mock 추천 서비스 클래스
class MockRecommendationService: BookRecommendable {
    func recommendBooks(for _: String, from _: [OwnedBook]) -> Single<BookMatchModuleOutput> {
        .just(BookMatchModuleOutput(
            ownedISBNs: [
                "9784063164130",
                "9784063164147",
            ],
            newBooks: mockBookData,
            description: "이러한 이유로 당신에게 책을 추천합니당"
        )
        )
    }
    
    func recommendBooks(from _: [OwnedBook]) -> Single<[BookItem]> {
        .just([])
    }

    let mockBookData = [
        BookItem(
            id: "12313",
            title: "Swift Programming",
            link: "https://bookstore.com/1234567890123",
            image: "https://bookstore.com/images/1234567890123.jpg",
            author: "John Doe",
            discount: "20%",
            publisher: "TechBooks",
            isbn: "1234567890123",
            description: "A comprehensive guide to Swift programming.",
            pubdate: "2024-01-15"
        ),
        BookItem(
            id: "12313",
            title: "Swift Programming",
            link: "https://bookstore.com/1234567890123",
            image: "https://bookstore.com/images/1234567890123.jpg",
            author: "John Doe",
            discount: "20%",
            publisher: "TechBooks",
            isbn: "1234567890123",
            description: "A comprehensive guide to Swift programming.",
            pubdate: "2024-01-15"
        ),
        BookItem(
            id: "12313",
            title: "Swift Programming",
            link: "https://bookstore.com/1234567890123",
            image: "https://bookstore.com/images/1234567890123.jpg",
            author: "John Doe",
            discount: "20%",
            publisher: "TechBooks",
            isbn: "1234567890123",
            description: "A comprehensive guide to Swift programming.",
            pubdate: "2024-01-15"
        ),
        BookItem(
            id: "12313",
            title: "Swift Programming",
            link: "https://bookstore.com/1234567890123",
            image: "https://bookstore.com/images/1234567890123.jpg",
            author: "John Doe",
            discount: "20%",
            publisher: "TechBooks",
            isbn: "1234567890123",
            description: "A comprehensive guide to Swift programming.",
            pubdate: "2024-01-15"
        ),
    ]

    let mockTestCompareData = [
        Book(
            isbn: "1234567890123",
            title: "Swift Programming",
            author: "John Doe",
            publisher: "TechBooks",
            thumbnailUrl: URL(string: "https://bookstore.com/images/1234567890123.jpg"),
            isOwned: false
        ),
        Book(
            isbn: "1234567890123",
            title: "Swift Programming",
            author: "John Doe",
            publisher: "TechBooks",
            thumbnailUrl: URL(string: "https://bookstore.com/images/1234567890123.jpg"),
            isOwned: false
        ),
        Book(
            isbn: "1234567890123",
            title: "Swift Programming",
            author: "John Doe",
            publisher: "TechBooks",
            thumbnailUrl: URL(string: "https://bookstore.com/images/1234567890123.jpg"),
            isOwned: false
        ),
        Book(
            isbn: "1234567890123",
            title: "Swift Programming",
            author: "John Doe",
            publisher: "TechBooks",
            thumbnailUrl: URL(string: "https://bookstore.com/images/1234567890123.jpg"),
            isOwned: false
        ),
    ]
}
