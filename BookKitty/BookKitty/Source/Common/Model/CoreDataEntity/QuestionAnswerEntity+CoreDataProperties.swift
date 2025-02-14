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
    @NSManaged public var bookQuestionAnswerLinks: NSSet?
}

// MARK: Generated accessors for bookQuestionAnswerLinks

extension QuestionAnswerEntity {
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

extension QuestionAnswerEntity: Identifiable {}
