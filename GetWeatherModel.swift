//
//  GetWeatherModel.swift
//  Daily Activity Monitoring System
//
//  Created by Allen P on 11/22/23.
//

import SwiftUI
import Foundation
import CoreData
import CoreLocation
import MapKit

struct WeatherResponse: Codable {
    struct Data: Codable {
        struct Values: Codable {
            let temperature: Double
            let humidity: Double
            let windSpeed: Double
            let weatherCode: Int
            // Add other fields as necessary
        }
        let values: Values
    }
    let data: Data
}
struct Location: Identifiable {
    var id = UUID()
    var name: String
    var coordinate: CLLocationCoordinate2D
}


class GetWeatherModel: ObservableObject {
    
    @Published var temperature: String = ""
    @Published var humidity: String = ""
    @Published var windSpeed: String = ""
    @Published var weatherCode: String = ""
    @Published var addressInput: String = ""
    
    
    func fetchWeather(){
        getWeatherData(address: addressInput)
    }

    //MARK fetchweather
    // Fetch weather data for a specific latitude and longitude.
    func getWeatherData(address: String) {
        guard let url = URL(string: "https://api.tomorrow.io/v4/weather/realtime?location=\(address)&apikey=9oaUsK5CVzmhk8AiyDzEM9umRA068M15") else {
            print("Invalid URL")
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error making request: \(error.localizedDescription)")
                return
            }

            guard let data = data else {
                print("No data received")
                return
            }

            do {
                let decodedResponse = try JSONDecoder().decode(WeatherResponse.self, from: data)
                DispatchQueue.main.async {
                    print("Weather: \(decodedResponse.data.values.weatherCode)")
                    print("Temperature: \(decodedResponse.data.values.temperature)°")
                    print("Humidity: \(decodedResponse.data.values.humidity)%")
                    print("Wind Speed: \(decodedResponse.data.values.windSpeed) km/h")
                    self.weatherCode = "Weather: \(decodedResponse.data.values.weatherCode)"
                    self.temperature = "Temperature: \(decodedResponse.data.values.temperature)°"
                    self.humidity = "Humidity: \(decodedResponse.data.values.humidity)%"
                    self.windSpeed = "Wind Speed: \(decodedResponse.data.values.windSpeed)km/h"
                }
            } catch {
                print("Error decoding response: \(error.localizedDescription)")
            }
        }
        task.resume()
    }
    
    func fetchLocation(region: Binding<MKCoordinateRegion>, markers: Binding<[Location]>) {
            forwardGeocoding(address: addressInput, region: region, markers: markers)
        }

    private func forwardGeocoding(address: String, region: Binding<MKCoordinateRegion>, markers: Binding<[Location]>) {
           CLGeocoder().geocodeAddressString(address, completionHandler: {(placemarks, error) in
               if error != nil {
                   print("Geocode failed: \(error!.localizedDescription)")
               } else if let placemarks = placemarks, let placemark = placemarks.first, let location = placemark.location {
                   let coords = location.coordinate
                   print("latitude: \(coords.latitude), longitude: \(coords.longitude)")
                   DispatchQueue.main.async {
                       region.wrappedValue.center = coords
                       markers.wrappedValue[0].name = placemark.locality ?? "Unknown"
                       markers.wrappedValue[0].coordinate = coords
                   }
               }
           })
       }

}

struct WeatherView: View {
    @ObservedObject var model = GetWeatherModel()
    
    @State private var region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 33.42555, longitude: -111.9400),
            span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
        )

        @State private var markers = [
            Location(name: "Tempe", coordinate: CLLocationCoordinate2D(latitude: 33.42555, longitude: -111.9400))
        ]

    var body: some View {
        VStack {
            TextField("Enter Address (e.g. London, Tempe...)", text: $model.addressInput)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            HStack {
                Button(action: {
                    model.fetchWeather()
                }) {
                    Image(systemName: "cloud")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.gray, lineWidth: 1)
                                )
                }

                Button(action: {
                    model.fetchLocation(region: $region, markers: $markers)
                }) {
                    Image(systemName: "map")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.gray, lineWidth: 1)
                                )
                }
            }
            Text(model.weatherCode)
            Text(model.temperature)
            Text(model.humidity)
            Text(model.windSpeed)
                .padding()
            
            Map(coordinateRegion: $region,
                interactionModes: .all,
                annotationItems: markers
            ){ location in
                MapMarker(coordinate: location.coordinate)
            }
            .ignoresSafeArea()

            Spacer()
        }
        .padding()
    }
}

