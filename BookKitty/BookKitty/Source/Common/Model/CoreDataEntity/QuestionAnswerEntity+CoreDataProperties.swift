//
//  QuestionAnswerEntity+CoreDataProperties.swift
//  BookKitty
//
//  Created by MaxBook on 2/6/25.
//
//

import CoreData
import Foundation

extension QuestionAnswerEntity {
    @nonobjc
    public class func fetchRequest() -> NSFetchRequest<QuestionAnswerEntity> {
        NSFetchRequest<QuestionAnswerEntity>(entityName: "QuestionAnswerEntity")
    }

    @NSManaged public var aiAnswer: String?
    @NSManaged public var id: UUID?
    @NSManaged public var userQuestion: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var bookQestionAnswerLinks: NSSet?
}

// MARK: Generated accessors for bookQestionAnswerLinks

extension QuestionAnswerEntity {
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

extension QuestionAnswerEntity: Identifiable {}
