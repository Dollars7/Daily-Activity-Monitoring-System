//
//  ContentView.swift
//  Daily Activity Monitoring System
//
//  Created by Allen P on 10/3/23.
//

import SwiftUI
import CoreData
import MapKit

struct ContentView: View {

//core data
    @Environment(\.managedObjectContext) private var context

    // Initialize the view models using the managed object context from the environment
    @StateObject var enterDataViewModel: EnterDataViewModel
    @StateObject var summaryViewModel: SummaryViewModel

    init() {
        let dataRepository = DataRepository(context: PersistenceController.shared.container.viewContext)
        _enterDataViewModel = StateObject(wrappedValue: EnterDataViewModel(context: PersistenceController.shared.container.viewContext))
        _summaryViewModel = StateObject(wrappedValue: SummaryViewModel(context: PersistenceController.shared.container.viewContext))
    }

    @State var currentData: String = ""
    @State var walkingMinutes: String = ""
    @State var runningMinutes: String = ""
    @State var sleepingHours: String = ""
    
    @State var searchDate: String = "" // Add a state for search if needed

    var body: some View {
        NavigationView {
            VStack {
                Image("celebration")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                Spacer()

                // Navigation link for Enter Daily Activity
                NavigationLink(destination: EnterDataView(viewModel: enterDataViewModel)){
                    Text("Enter Daily Activity")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
                
                // Navigation link for View Summary
                NavigationLink(destination: SummaryView(
                    viewModel: summaryViewModel)) {
                    Text("View Summary")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.yellow)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()

                NavigationLink(destination: DateRangeActivityView()) {
                    Text("View Activities by Date Range")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
                
                NavigationLink(destination: WeatherView()) {
                    Text("Get today's weather")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
                
            }
            .navigationTitle("Daily Activity Monitor")
        }    .onAppear {
            setupViewModels()
        }
    }
    func setupViewModels() {

    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.shared.container.viewContext
        ContentView()
            .environment(\.managedObjectContext, context)
    }
}

struct DateRangeActivityView: View {
    @Environment(\.managedObjectContext) var context
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var activities: [ActivityRecord] = []

    var body: some View {
        VStack {
            Form {
                DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                
                Button("Fetch Activities") {
                    print("Fetching activities...")
                    self.activities = fetchActivities(from: startDate, to: endDate)
                }
            }

            List(activities, id: \.self) { activity in
                VStack(alignment: .leading) {
                    Text("Date: \(activity.date ?? Date(), formatter: itemFormatter)")
                    Text("Walking Minutes: \(activity.walkingMinutes)")
                    Text("Running Minutes: \(activity.runningMinutes)")
                    Text("Sleeping Hours: \(activity.sleepingHours)")
                    Text("Food Intake Calories: \(activity.foodIntakeCalories)")
                }
            }
        }
    }

    private func fetchActivities(from startDate: Date, to endDate: Date) -> [ActivityRecord] {
        let dataRepository = DataRepository(context: context)
        return dataRepository.fetchActivities(from: startDate, to: endDate)
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .long
    formatter.timeStyle = .none
    return formatter
}()
