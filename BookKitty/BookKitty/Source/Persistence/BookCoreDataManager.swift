//
//  BookCoreDataManager.swift
//  BookKitty
//
//  Created by 권승용 on 1/23/25.
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
}

/// Book 엔티티를 관리하는 객체
final class BookCoreDataManager: BookCoreDataManageable {
    // MARK: Internal

    /// BookEntity 객체를 프레젠테이션 레이어의 Book 모델로 변경하기
    /// - Parameter entity: BookEntity 객체
    /// - Returns: 옵셔널 Book 모델 객체
    func entityToModel(entity: BookEntity) -> Book? {
        guard let isbn = entity.isbn, let title = entity.title,
              let author = entity.author else {
            return nil
        }

        return Book(
            isbn: isbn,
            title: title,
            author: author,
            publisher: entity.publisher ?? "",
            thumbnailUrl: URL(string: entity.imageLink ?? ""),
            isOwned: entity.isOwned,
            bookInfoLink: entity.bookInfoLink ?? "",
            createdAt: entity.createdAt ?? Date(),
            updatedAt: entity.updatedAt ?? Date(),
            description: entity.descriptions ?? "",
            price: entity.price ?? "100",
            pubDate: entity.pubDate ?? "2999-01-01"
        )
    }

    /// 새로운 Book Entity 객체를 저장하기
    /// - Parameter :
    ///   - model: 저장하고자 하는 Book 모델 객체
    ///   - context:  코어데이터 컨텍스트
    /// - Returns: 성공 여부를 Bool 타입으로 반환
    func insertBook(model: Book, context: NSManagedObjectContext) -> Bool {
        do {
            _ = modelToEntity(model: model, context: context)
            try context.save()
            return true
        } catch {
            print("저장 실패: \(error.localizedDescription)")
            return false
        }
    }

    /// 여러 권의 책 데이터 저장을 위해 여러 개의 Book 모델을 BookEntity로 변환
    /// - Parameters:
    ///   - data: 변환하고자 하는 Book 모델의 배열
    ///   - context: 코어데이터 컨텍스트
    /// - Returns: BookEntity 배열
    func createMultipleBooksWithoutSave(
        data: [Book],
        context: NSManagedObjectContext
    ) -> [BookEntity] {
        data.map { modelToEntity(model: $0, context: context) }
    }

    /// isbn에 해당하는 책 데이터 가져오기
    /// - Parameters:
    ///   - isbn: 책의 고유 isbn값
    ///   - context: 코어데이터 컨텍스트
    /// - Returns: 해당 isbn 값을 가지고 있는 BookEntity
    func selectBookByIsbn(isbn: String, context: NSManagedObjectContext) -> BookEntity? {
        let request: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()
        request.predicate = NSPredicate(format: "isbn == %@", isbn)

        do {
            if let bookEntity = try context.fetch(request).first {
                if bookEntity.isbn == isbn {
                    return bookEntity
                }
            }
            return nil
        } catch {
            print("책 데이터 가져오기 실패: \(error.localizedDescription)")
            return nil
        }
    }

    /// 책장 책 목록 가져오기
    /// - Parameters:
    ///   - offset: 책을 가져오기 시작하는 지점
    ///   - limit: 한번에 가져오는 책의 최대 개수
    ///   - context: 코어데이터 컨텍스트
    /// - Returns: 조건을 충족하는 BookEntity 배열
    func selectOwnedBooks(
        offset: Int,
        limit: Int,
        context: NSManagedObjectContext
    ) -> [BookEntity] {
        let request: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()
        request.predicate = NSPredicate(format: "isOwned == %@", NSNumber(value: true))
        request.fetchOffset = offset
        request.fetchLimit = limit

        // updatedAt 내림차순 정렬 추가
        let sortDescriptor = NSSortDescriptor(key: "updatedAt", ascending: false)
        request.sortDescriptors = [sortDescriptor]

        do {
            return try context.fetch(request)
        } catch {
            print("책장 책 목록 가져오기 실패: \(error.localizedDescription)")
            return []
        }
    }

    /// isbn 리스트로 해당하는 책 데이터 가져오기
    /// - Parameters:
    ///   - isbnList: isbn 문자열이 담긴 배열
    ///   - context: 코어데이터 컨텍스트
    /// - Returns: BookEntity의 배열
    func selectBooksWithIsbnArray(
        isbnList: [String],
        context: NSManagedObjectContext
    ) -> [BookEntity] {
        let request: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()
        request.predicate = NSPredicate(format: "isbn IN %@", isbnList)

        do {
            return try context.fetch(request)
        } catch {
            print("ISBN 목록으로 책 데이터 가져오기 실패: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: Private

    /// 모델을 코어데이터에 저장하기 위해 entity를 생성해주는 메소드
    /// - Parameters:
    ///   - model: 저장하고자 하는 Book 모델 객체
    ///   - context:  코어데이터 컨텍스트
    /// - Returns: 변환 된 BookEntity 객체
    private func modelToEntity(model: Book, context: NSManagedObjectContext) -> BookEntity {
        let entity = BookEntity(context: context)

        entity.author = model.author
        entity.bookInfoLink = model.bookInfoLink
        entity.createdAt = Date()
        entity.updatedAt = Date()
        entity.descriptions = model.description
        entity.imageLink = model.thumbnailUrl?.absoluteString
        entity.isbn = model.isbn
        entity.isOwned = model.isOwned
        entity.price = model.price
        entity.pubDate = model.pubDate
        entity.publisher = model.publisher
        entity.title = model.title

        return entity
    }
}
