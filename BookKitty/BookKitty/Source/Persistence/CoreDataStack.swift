//
//  CoreDataStack.swift
//  BookKitty
//
//  Created by 임성수 on 2/6/25.
//

import CoreData

final class CoreDataStack {
    // MARK: - Lifecycle

    private init() {
        persistentContainer = NSPersistentContainer(name: "MyAppModel") // 모델 파일명
        persistentContainer.loadPersistentStores { _, error in
            if let error {
                fatalError("CoreData 로드 실패: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Internal

    static let shared = CoreDataStack()

    var persistentContainer: NSPersistentContainer

    var context: NSManagedObjectContext { persistentContainer.viewContext }

    func save() {
        guard context.hasChanges else {
            return
        }

        do {
            try context.save()
        } catch {
            print("저장 실패: \(error.localizedDescription)")
        }
    }
}
