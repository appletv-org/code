//
//  CoreDataManager.swift
//  iptv
//
//  Created by Александр Колганов on 21.09.16.
//  Copyright © 2016 Home. All rights reserved.
//

import CoreData
import Foundation

class CoreDataManager {
    
    // Singleton
    static let instance = CoreDataManager()
    
    private init() {}
    
    
    // Entity for Name
    func entityForName(entityName: String) -> NSEntityDescription {
        return NSEntityDescription.entity(forEntityName: entityName, in: self.managedObjectContext)!
    }
    
    // Fetched Results Controller for Entity Name
    func fetchedResultsController(entityName: String, keyForSort: String) -> NSFetchedResultsController<NSFetchRequestResult> {
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        let sortDescriptor = NSSortDescriptor(key: keyForSort, ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataManager.instance.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        
        return fetchedResultsController
    }
    
    // MARK: - Core Data stack
    
    lazy var coreDataDirectory: URL = {
        return  FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
    }()!
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        let modelURL = Bundle.main.url(forResource: "iptv", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        /*
        objc_sync_enter(self)
        defer {
            objc_sync_exit(self)
        }
         */
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.coreDataDirectory.appendingPathComponent("iptv.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
        } catch {
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject?
            dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject?
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        
        return coordinator
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        let coordinator = self.persistentStoreCoordinator
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    public class func concurrentContext() -> NSManagedObjectContext { //for operation with many change/delete/save
        let dbcontext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        dbcontext.parent = CoreDataManager.instance.managedObjectContext
        return dbcontext
    }
    
    public class func saveConcurrentContext(_ concurrentContext:NSManagedObjectContext) {
        let moc = CoreDataManager.context()
        do {
            try concurrentContext.save()
            moc.performAndWait {
                do {
                    try moc.save()
                } catch {
                    fatalError("Failure to save context: \(error)")
                }
            }
        } catch {
            fatalError("Failure to save concurent context: \(error)")
        }
    }
    
    public class func simpleRequest<T : NSManagedObject>(_ predicate: NSPredicate, context: NSManagedObjectContext = CoreDataManager.context()) -> [T] {
        if let fetchRequest: NSFetchRequest<T> = T.fetchRequest() as? NSFetchRequest<T> {
            fetchRequest.predicate = predicate
            if let result = try? context.fetch(fetchRequest) {
                return result
            }
        }
        return []
    }

    public class func requestFirstElement<T : NSManagedObject>(_ predicate: NSPredicate, context: NSManagedObjectContext = CoreDataManager.context()) -> T? {
        let elements : [T] = CoreDataManager.simpleRequest(predicate, context:context)
        if elements.count > 0 {
            return elements[0]
        }
        return nil
    }

    
    
    public class func context()  -> NSManagedObjectContext {
        return CoreDataManager.instance.managedObjectContext
    }
    
}
