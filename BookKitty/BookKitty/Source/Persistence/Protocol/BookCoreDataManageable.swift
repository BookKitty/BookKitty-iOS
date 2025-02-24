//
//  BookCoreDataManageable.swift
//  BookKitty
//
//  Created by 권승용 on 2/11/25.
//

import CoreData

/// Book 엔티티를 관리하는 코어 데이터 매니저 기능을 추상화하는 프로토콜
protocol BookCoreDataManageable {
    func entityToModel(entity: BookEntity) -> Book?
    func insertBook(model: Book, context: NSManagedObjectContext) -> Bool
    func createMultipleBooksWithoutSave(data: [Book], context: NSManagedObjectContext)
        -> [BookEntity]
    func selectBookByIsbn(isbn: String, context: NSManagedObjectContext) -> BookEntity?
    func selectOwnedBooks(offset: Int, limit: Int, context: NSManagedObjectContext) -> [BookEntity]
    func selectBooksWithIsbnArray(isbnList: [String], context: NSManagedObjectContext)
        -> [BookEntity]
    func modelToEntity(model: Book, context: NSManagedObjectContext) -> BookEntity
    func readOwnedBooksCount(context: NSManagedObjectContext) -> Int
}
