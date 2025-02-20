//
//  MockBookOCRKit.swift
//  BookKitty
//
//  Created by 권승용 on 2/19/25.
//

import BookMatchCore
import BookOCRKit
import Foundation
import RxSwift
import UIKit

final class MockBookOCRKit: BookMatchable {
    func recognizeBookFromImage(_: UIImage) -> Single<BookItem> {
        .just(BookItem(
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
        ))
    }

    func searchBookFromText(_: String) -> Single<[BookMatchCore.BookItem]> {
        .just(
            [
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
        )
    }
}
