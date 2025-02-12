//
//  CoreDataStack.swift
//  BookKitty
//
//  Created by 임성수 on 2/6/25.
//

import CoreData

final class CoreDataStack {
    // MARK: - Static Properties

    // MARK: - Internal

    static let shared = CoreDataStack()

    // MARK: - Properties

    var persistentContainer: NSPersistentContainer

    // MARK: - Computed Properties

    var context: NSManagedObjectContext { persistentContainer.viewContext }

    // MARK: - Lifecycle

    private init() {
        persistentContainer = NSPersistentContainer(name: "BookKitty") // 모델 파일명
        persistentContainer.loadPersistentStores { _, error in
            if let error {
                fatalError("CoreData 로드 실패: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Functions

    func save() {
        guard context.hasChanges else {
            return
        }

        do {
            try context.save()
        } catch {
            BookKittyLogger.log("저장 실패: \(error.localizedDescription)")
        }
    }
}
