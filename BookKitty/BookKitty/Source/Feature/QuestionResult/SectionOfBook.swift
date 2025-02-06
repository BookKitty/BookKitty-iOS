//
//  SectionOfBook.swift
//  BookKitty
//
//  Created by 권승용 on 2/5/25.
//

import RxDataSources

struct SectionOfBook {
    var items: [Item]
}

extension SectionOfBook: SectionModelType {
    typealias Item = Book

    init(original: SectionOfBook, items: [Book]) {
        self = original
        self.items = items
    }
}
