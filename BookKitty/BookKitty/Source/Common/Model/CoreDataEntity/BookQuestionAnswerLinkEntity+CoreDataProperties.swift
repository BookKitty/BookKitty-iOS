//
//  BookQuestionAnswerLinkEntity+CoreDataProperties.swift
//  BookKitty
//
//  Created by MaxBook on 2/6/25.
//
//

import Foundation
import CoreData


extension BookQuestionAnswerLinkEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BookQuestionAnswerLinkEntity> {
        return NSFetchRequest<BookQuestionAnswerLinkEntity>(entityName: "BookQuestionAnswerLinkEntity")
    }

    @NSManaged public var createdAt: Date?
    @NSManaged public var book: BookEntity?
    @NSManaged public var questionAnswer: QuestionAnswerEntity?

}

extension BookQuestionAnswerLinkEntity : Identifiable {

}
