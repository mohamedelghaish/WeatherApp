//
//  CoreDataManager.swift
//  WeatherApp
//
//  Created by Mohamed Kotb on 17/07/2025.
//

import Foundation
import CoreData
import UIKit

final class CoreDataManager {
    static let shared = CoreDataManager()
    
    private init() {}

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "WeatherApp")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data Error: \(error)")
            }
        }
        return container
    }()

    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    func saveContext() {
        if context.hasChanges {
            print("saved succssfully")
            try? context.save()
        }
    }
}
