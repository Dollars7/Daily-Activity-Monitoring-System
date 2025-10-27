//
//  Daily_Activity_Monitoring_SystemApp.swift
//  Daily Activity Monitoring System
//
//  Created by Allen P on 10/3/23.
//

import SwiftUI
import CoreData

@main
struct Daily_Activity_Monitoring_SystemApp: App {
    let persistenceController = PersistenceController.shared
    
    init() {
        #if DEBUG
        deleteAllActivityRecords()
        #endif
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
    // Function to delete all ActivityRecord entries
        func deleteAllActivityRecords() {
            let context = persistenceController.container.viewContext
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "ActivityRecord")
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

            do {
                try context.execute(deleteRequest)
                try context.save()
                print("All activity records have been deleted.")
            } catch let error as NSError {
                print("Error deleting all activity records: \(error), \(error.userInfo)")
            }
        }
}

