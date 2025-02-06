//
//  BookQuestionAnswerLinkEntity+CoreDataProperties.swift
//  BookKitty
//
//  Created by 임성수 on 2/6/25.
//
//

import CoreData
import Foundation

extension BookQuestionAnswerLinkEntity {
    @nonobjc
    public class func fetchRequest() -> NSFetchRequest<BookQuestionAnswerLinkEntity> {
        NSFetchRequest<BookQuestionAnswerLinkEntity>(entityName: "BookQuestionAnswerLinkEntity")
    }

    @NSManaged public var createdAt: Date?
    @NSManaged public var book: BookEntity?
    @NSManaged public var questionAnswer: QuestionAnswerEntity?
}

extension BookQuestionAnswerLinkEntity: Identifiable {}
