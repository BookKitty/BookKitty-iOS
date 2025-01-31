//
//  Book.swift
//  BookKitty
//
//  Created by 권승용 on 1/29/25.
//

import Foundation

struct Book: Hashable {
    let isbn: String
    let title: String
    let author: String
    let publisher: String
    let thumbnailUrl: URL?
}
