//
//  Book.swift
//  BookKitty
//
//  Created by 권승용 on 1/29/25.
//

import Foundation
import RxDataSources

struct Book: IdentifiableType, Hashable {
    let isbn: String
    let title: String
    let author: String
    let publisher: String
    let thumbnailUrl: URL?
    var isOwned = false

    var identity: String {
        isbn
    }
}
