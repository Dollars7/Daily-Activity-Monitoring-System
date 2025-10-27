//
//  EnterDataViewModel.swift
//  Daily Activity Monitoring System
//
//  Created by Allen P on 10/3/23.
//

import SwiftUI
import Foundation
import CoreData
import CoreLocation
import MapKit


class EnterDataViewModel: ObservableObject {
    // Add the managed object context
    var context: NSManagedObjectContext
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // 可以是用户当前位置或默认位置
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    // Inject the context through the initializer
    init(context: NSManagedObjectContext) {
            self.context = context

        }

        @Published var currentDate: Date = Date()
        @Published var walkingMinutes: Int = 0
        @Published var runningMinutes: Int = 0
        @Published var sleepingHours: Double = 0.0
        @Published var foodIntakeCalories: Int = 0
        @Published var location: String = ""  // New location property
        @Published var uniqueID = UUID()
        @Published var selectedLocationName : String = ""
    // Add a reference to the SummaryViewModel and LifestyleViewModel
    var summaryViewModel: SummaryViewModel?

    
    // Method to save the entered data to the Model (DailyActivity)
    func saveDailyActivity(runningMinutes: Int16, walkingMinutes: Int16, sleepHours: Double) {
        // Validate data before saving
        guard
            walkingMinutes >= 0,
            runningMinutes >= 0,
            sleepingHours >= 0,
            foodIntakeCalories >= 0
//            !location.isEmpty  // Ensure location is not empty
        else {
            // Handle invalid data, display an error, or prevent saving
            print("Invalid data. Please check your input.")
            return
        }

        // Print the values you're trying to save for debugging
        print("Saving data: \(currentDate), \(walkingMinutes), \(runningMinutes), \(sleepingHours), \(foodIntakeCalories)")
        // Create a fetch request to check if a record for the current date already exists
        let request: NSFetchRequest<ActivityRecord> = ActivityRecord.fetchRequest()
            request.predicate = NSPredicate(format: "date == %@", currentDate as NSDate)
            
            do {
                let results = try context.fetch(request)
                let activityRecord: ActivityRecord

                if let existingRecord = results.first {
                    // Update existing record
                    activityRecord = existingRecord
                } else {
                    // Create new record
                    activityRecord = ActivityRecord(context: context)
                    activityRecord.date = currentDate
                    activityRecord.uniqueId = UUID()  // Assign a new UUID for new records
                }

                // Set the fields for both new and existing records
                activityRecord.walkingMinutes = Int16(walkingMinutes)
                activityRecord.runningMinutes = Int16(runningMinutes)
                activityRecord.sleepingHours = sleepingHours
                activityRecord.foodIntakeCalories = Int32(foodIntakeCalories)
                activityRecord.location = location  // Set the new location field

                try context.save()
                print("Data saved or updated successfully!")
                clearDailyActivity()  // Clear the input fields after saving or updating
            } catch {
                print("Error saving or updating data: \(error.localizedDescription)")
            }
    }
    
    // Method to clear the input fields
    func clearDailyActivity() {
        currentDate = Date()
        walkingMinutes = 0
        runningMinutes = 0
        sleepingHours = 0.0
        foodIntakeCalories = 0
        location = ""
        uniqueID = UUID()
        print("Clearing data...")
    }

    func setLocation(_ coordinate: CLLocationCoordinate2D) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)) { (placemarks, error) in
            if let placemark = placemarks?.first, let locality = placemark.locality {
                DispatchQueue.main.async {
                    self.location = locality // This updates the location property with the locality name
                }
            }
        }
    }
    func updateLocation(_ coordinate: CLLocationCoordinate2D) {
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)) { [weak self] placemarks, error in
                guard let self = self, error == nil, let placemark = placemarks?.first else { return }
                self.location = "\(placemark.locality ?? ""), \(placemark.administrativeArea ?? ""), \(placemark.country ?? "")"
            }
        }
    func handleSelectedLocation(annotation: MKPointAnnotation) {
        let locationString = "\(annotation.coordinate.latitude),\(annotation.coordinate.longitude)"
        let locationName = annotation.title ?? "Unknown"

        // 假设您要将地点名称和坐标存储为一个字符串
        let locationInfo = "\(locationName): \(locationString)"
        self.location = locationInfo
    }

    func fetchWeatherData(latitude: Double, longitude: Double, completion: @escaping (WeatherData?, Error?) -> Void) {
        let username = "allanp" // Replace with your actual username
        let urlString = "http://api.geonames.org/findNearByWeatherJSON?formatted=true&lat=\(latitude)&lng=\(longitude)&username=\(username)&style=full"
        guard let url = URL(string: urlString) else { return }
        
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                completion(nil, error)
                return
            }
            guard let data = data else {
                completion(nil, NSError(domain: "", code: -1, userInfo: nil))
                return
            }
            do {
                // Assuming 'weather' is the key where weather details are stored in the JSON response.
                let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                let weatherDetails = jsonResponse?["weather"] as? [String: Any]
                let weatherCondition = weatherDetails?["condition"] as? String ?? "Not Available"
                let temperature = weatherDetails?["temperature"] as? String ?? "Not Available"
                let weatherData = WeatherData(weatherCondition: weatherCondition, temperature: Double(temperature) ?? 0.0)
                completion(weatherData, nil)
            } catch {
                completion(nil, error)
            }
        }
        task.resume()
    }


}


struct EnterDataView: View {
    @ObservedObject var viewModel: EnterDataViewModel
    
    @State private var showSaveAlert: Bool = false
    @State private var showClearAlert: Bool = false
    @State private var showingMap = false
    @StateObject private var mapViewModel = MapViewModel()
    @State private var searchQuery = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Enter Daily Activity")) {
                    DatePicker("Date", selection: $viewModel.currentDate, displayedComponents: .date)
                    Stepper("Walking Minutes: \(viewModel.walkingMinutes)", value: $viewModel.walkingMinutes)
                    Stepper("Running Minutes: \(viewModel.runningMinutes)", value: $viewModel.runningMinutes)
                    Stepper("Sleeping Hours: \(viewModel.sleepingHours, specifier: "%.1f")", value: $viewModel.sleepingHours, in: 0...24, step: 0.5)
                    Stepper("Food Intake Calories: \(viewModel.foodIntakeCalories)", value: $viewModel.foodIntakeCalories)
                }
                Image("mind-blowing")
                    .resizable()
                    .aspectRatio(contentMode: .fit)

            }
            .navigationTitle("Daily Activity")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        showSaveAlert = true
                        viewModel.saveDailyActivity(runningMinutes: Int16(viewModel.runningMinutes), walkingMinutes: Int16(viewModel.walkingMinutes), sleepHours: viewModel.sleepingHours)
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear") {
                        viewModel.clearDailyActivity()
                        showClearAlert = true
                    }
                }
            }
            .alert(isPresented: $showSaveAlert) {
                Alert(
                    title: Text("Success"),
                    message: Text("Data saved successfully!"),
                    dismissButton: .default(Text("Okay"))
                )
            }
            .alert(isPresented: $showClearAlert) {
                Alert(
                    title: Text("Cleared"),
                    message: Text("Data cleared successfully!"),
                    dismissButton: .default(Text("Okay"))
                )
            }
        }//Nav
    }
}

// Define the structure of the weather data based on the GeoNames API response format.
struct WeatherData: Codable {
    let weatherCondition: String
    let temperature: Double
    // Add more properties as needed based on the API's response.
}
