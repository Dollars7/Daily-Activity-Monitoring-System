//
//  DataRepository.swift
//  Daily Activity Monitoring System
//
//  Created by Allen P on 10/3/23.


import Foundation
import CoreData

class DataRepository {
    //coredata
    var context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }
    // Function to add or update an ActivityRecord, now including weather data
        func addActivityRecord(date: Date, walkingMinutes: Int, runningMinutes: Int, sleepingHours: Double, foodIntakeCalories: Int, location: String, temperature: Double, weatherCondition: Double) {
            let request: NSFetchRequest<ActivityRecord> = ActivityRecord.fetchRequest()
            request.predicate = NSPredicate(format: "date == %@", date as NSDate)

            do {
                let results = try context.fetch(request)
                let activityRecord: ActivityRecord

                if let existingRecord = results.first {
                    // Update existing record
                    activityRecord = existingRecord
                } else {
                    // Create new record
                    activityRecord = ActivityRecord(context: context)
                    activityRecord.date = date
                    activityRecord.uniqueId = UUID()  // Assign a new UUID for new records
                }

                // Set the fields for both new and existing records
                activityRecord.walkingMinutes = Int16(walkingMinutes)
                activityRecord.runningMinutes = Int16(runningMinutes)
                activityRecord.sleepingHours = sleepingHours
                activityRecord.foodIntakeCalories = Int32(foodIntakeCalories)
                activityRecord.location = location  // Set the new location field
                activityRecord.temperature = temperature  // Set the new temperature field
                activityRecord.weatherCondition = weatherCondition  // Set the new weather condition field

                try context.save()
            } catch {
                print("Error saving or updating the activity record: \(error.localizedDescription)")
            }
        }
//    // Function to add or update an ActivityRecord
//        func addActivityRecord(date: Date, walkingMinutes: Int, runningMinutes: Int, sleepingHours: Double, foodIntakeCalories: Int, location: String) {
//            let request: NSFetchRequest<ActivityRecord> = ActivityRecord.fetchRequest()
//            request.predicate = NSPredicate(format: "date == %@", date as NSDate)
//
//            do {
//                let results = try context.fetch(request)
//                let activityRecord: ActivityRecord
//
//                if let existingRecord = results.first {
//                    // Update existing record
//                    activityRecord = existingRecord
//                } else {
//                    // Create new record
//                    activityRecord = ActivityRecord(context: context)
//                    activityRecord.date = date
//                    activityRecord.uniqueId = UUID()  // Assign a new UUID for new records
//                }
//
//                // Set the fields for both new and existing records
//                activityRecord.walkingMinutes = Int16(walkingMinutes)
//                activityRecord.runningMinutes = Int16(runningMinutes)
//                activityRecord.sleepingHours = sleepingHours
//                activityRecord.foodIntakeCalories = Int32(foodIntakeCalories)
//                activityRecord.location = location  // Set the new location field
//
//                try context.save()
//            } catch {
//                print("Error saving or updating the activity record: \(error.localizedDescription)")
//            }
//        }
    
    func fetchActivities(from startDate: Date, to endDate: Date) -> [ActivityRecord] {
        let fetchRequest: NSFetchRequest<ActivityRecord> = ActivityRecord.fetchRequest()
        
        // Predicate to fetch records within the date range
        let datePredicate = NSPredicate(format: "(date >= %@) AND (date <= %@)", startDate as NSDate, endDate as NSDate)
        fetchRequest.predicate = datePredicate

        do {
            let results = try context.fetch(fetchRequest)
            return results
        } catch let error as NSError {
            print("Could not fetch activities: \(error), \(error.userInfo)")
            return []
        }
    }


    func fetchLastSevenDaysActivities() -> [ActivityRecord] {
           let fetchRequest: NSFetchRequest<ActivityRecord> = ActivityRecord.fetchRequest()
           let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
           let datePredicate = NSPredicate(format: "(date >= %@)", sevenDaysAgo as NSDate)
           fetchRequest.predicate = datePredicate

           do {
               return try context.fetch(fetchRequest)
           } catch {
               print("Error fetching last seven days' activities: \(error)")
               return []
           }
       }
    // Function to delete all ActivityRecord entries
        func deleteAllActivityRecords() {
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = ActivityRecord.fetchRequest()
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

