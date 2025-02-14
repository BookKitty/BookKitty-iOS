//
//  BookEntity+CoreDataProperties.swift
//  BookKitty
//
//  Created by MaxBook on 2/6/25.
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
    @NSManaged public var isOwned: Bool
    @NSManaged public var updatedAt: Date?
    @NSManaged public var bookQuestionAnswerLinks: NSSet?
}

// MARK: Generated accessors for bookQuestionAnswerLinks

extension BookEntity {
    @objc(addBookQuestionAnswerLinksObject:)
    @NSManaged
    public func addToBookQuestionAnswerLinks(_ value: BookQuestionAnswerLinkEntity)

    @objc(removeBookQuestionAnswerLinksObject:)
    @NSManaged
    public func removeFromBookQuestionAnswerLinks(_ value: BookQuestionAnswerLinkEntity)

    @objc(addBookQuestionAnswerLinks:)
    @NSManaged
    public func addToBookQuestionAnswerLinks(_ values: NSSet)

    @objc(removeBookQuestionAnswerLinks:)
    @NSManaged
    public func removeFromBookQuestionAnswerLinks(_ values: NSSet)
}

extension BookEntity: Identifiable {}
