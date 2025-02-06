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

enum SectionType: Hashable {
    case main
}

extension SectionOfBook: AnimatableSectionModelType {
    typealias Identity = SectionType
    typealias Item = Book

    var identity: SectionType {
        .main
    }

    init(original: SectionOfBook, items: [Book]) {
        self = original
        self.items = items
    }
}
