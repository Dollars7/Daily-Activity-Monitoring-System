//
//  SummaryViewModel.swift
//  Daily Activity Monitoring System
//
//  Created by Allen P on 10/3/23.
//

import SwiftUI
import Foundation
import CoreData

class SummaryViewModel: ObservableObject {
    
    @Published var activities: [ActivityRecord] = []
    var dataRepository: DataRepository
    var context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
        self.dataRepository = DataRepository(context: context)
        fetchActivities()
    }

    func fetchActivities(from startDate: Date? = nil, to endDate: Date? = nil) {
        var fetchRequest: NSFetchRequest<ActivityRecord> = ActivityRecord.fetchRequest()

        if let start = startDate, let end = endDate {
            fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date <= %@", argumentArray: [start, end])
        }

        do {
            self.activities = try context.fetch(fetchRequest)
        } catch {
            print("Error fetching activities: \(error)")
        }
    }
    
    func calculateSummaryData() -> (totalWalkingMinutes: Int, totalRunningMinutes: Int, totalSleepingHours: Double, totalFoodIntakeCalories: Int) {
        let totals = activities.reduce((0, 0, 0.0, 0)) { acc, activity in
            (
                acc.0 + Int(activity.walkingMinutes),
                acc.1 + Int(activity.runningMinutes),
                acc.2 + activity.sleepingHours,
                acc.3 + Int(activity.foodIntakeCalories)
            )
        }
        return totals
    }
}


struct SummaryView: View {
    @ObservedObject var viewModel: SummaryViewModel
    @Environment(\.managedObjectContext) var context
    @State private var startDate = Date()
    @State private var endDate = Date()

    var barChartData: [(value: Double, color: Color)] {
        [
            (value: Double(viewModel.calculateSummaryData().totalWalkingMinutes), color: Color.blue),
            (value: Double(viewModel.calculateSummaryData().totalRunningMinutes), color: Color.green),
            (value: viewModel.calculateSummaryData().totalSleepingHours * 60, color: Color.yellow),
            (value: Double(viewModel.calculateSummaryData().totalFoodIntakeCalories) / 10, color: Color.orange)
        ]
    }

    var body: some View {
        VStack {
            DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
            DatePicker("End Date", selection: $endDate, displayedComponents: .date)
            
            Button("Fetch Activities") {
                viewModel.fetchActivities(from: startDate, to: endDate)
            }
            
            List {
                Section(header: Text("Summary").font(.title)) {
                    Text("Total Walking Minutes: \(viewModel.calculateSummaryData().totalWalkingMinutes)")
                    Text("Total Running Minutes: \(viewModel.calculateSummaryData().totalRunningMinutes)")
                    Text("Total Sleeping Hours: \(viewModel.calculateSummaryData().totalSleepingHours, specifier: "%.1f")")
                    Text("Total Food Intake Calories: \(viewModel.calculateSummaryData().totalFoodIntakeCalories)")
                }

                Section(header: Text("Details").font(.title2)) {
                    ForEach(viewModel.activities, id: \.self) { activity in
                        DisclosureGroup("\(activity.date ?? Date(), formatter: itemFormatter)") {
                            Text("Walking Minutes: \(activity.walkingMinutes)")
                            Text("Running Minutes: \(activity.runningMinutes)")
                            Text("Sleeping Hours: \(activity.sleepingHours, specifier: "%.1f")")
                            Text("Food Intake Calories: \(activity.foodIntakeCalories)")
                        }
                    }
                }
                
                Section() {
                    BarChart(data: barChartData)
                        .padding()
                }
            }
            .listStyle(GroupedListStyle())
        }
        .padding([.leading, .trailing])
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .long
    formatter.timeStyle = .none
    return formatter
}()



//----------------bar
struct Bar: View {
    var value: CGFloat
    var color: Color
    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: 30, height: value)
    }
}

struct BarChart: View {
    var data: [(value: Double, color: Color)]

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            ForEach(data.indices, id: \.self) { index in // Use \.self as the ID for each item
                let item = data[index]
                Bar(value: CGFloat(item.value), color: item.color)
            }
        }
    }
}
