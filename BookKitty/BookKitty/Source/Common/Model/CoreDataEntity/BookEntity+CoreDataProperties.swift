//
//  BookEntity+CoreDataProperties.swift
//  BookKitty
//
//  Created by 임성수 on 2/6/25.
//
//

import CoreData
import Foundation

extension BookEntity {
    @nonobjc
    public class func fetchRequest() -> NSFetchRequest<BookEntity> {
        NSFetchRequest<BookEntity>(entityName: "BookEntity")
    }

    @NSManaged public var author: String?
    @NSManaged public var bookInfoLink: String?
    @NSManaged public var descriptions: String?
    @NSManaged public var imageLink: String?
    @NSManaged public var isbn: String?
    @NSManaged public var price: String?
    @NSManaged public var pubDate: String?
    @NSManaged public var publisher: String?
    @NSManaged public var title: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var bookQestionAnswerLinks: NSSet?
}

// MARK: Generated accessors for bookQestionAnswerLinks

extension BookEntity {
    @objc(addBookQestionAnswerLinksObject:)
    @NSManaged
    public func addToBookQestionAnswerLinks(_ value: BookQuestionAnswerLinkEntity)

    @objc(removeBookQestionAnswerLinksObject:)
    @NSManaged
    public func removeFromBookQestionAnswerLinks(_ value: BookQuestionAnswerLinkEntity)

    @objc(addBookQestionAnswerLinks:)
    @NSManaged
    public func addToBookQestionAnswerLinks(_ values: NSSet)

    @objc(removeBookQestionAnswerLinks:)
    @NSManaged
    public func removeFromBookQestionAnswerLinks(_ values: NSSet)
}

extension BookEntity: Identifiable {}
