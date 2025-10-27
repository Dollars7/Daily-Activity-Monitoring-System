//
//  MapView.swift
//  Daily Activity Monitoring System
//
//  Created by Allen P on 11/21/23.
//

import SwiftUI
import MapKit
import CoreData
import CoreLocation
import Foundation


class MapViewModel: ObservableObject {
    @Published var searchResults: [MKMapItem] = []
    @Published var selectedCoordinate: CLLocationCoordinate2D?
    func searchPlaces(query: String, region: MKCoordinateRegion) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = region

        let search = MKLocalSearch(request: request)
        search.start { response, _ in
            DispatchQueue.main.async {
                self.searchResults = response?.mapItems ?? []
            }
        }
    }
}


struct MapView: UIViewRepresentable {
    @Binding var selectedLocation: String
    @ObservedObject var viewModel: MapViewModel

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.removeAnnotations(uiView.annotations)
        for item in viewModel.searchResults {
            let annotation = MKPointAnnotation()
            annotation.coordinate = item.placemark.coordinate
            annotation.title = item.name
            uiView.addAnnotation(annotation)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView

        init(_ parent: MapView) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            if let coordinate = view.annotation?.coordinate, let title = view.annotation?.title {
                let locationString = "\(coordinate.latitude),\(coordinate.longitude)"
                DispatchQueue.main.async {
                    self.parent.selectedLocation = "\(title ?? "Unknown Location"): \(locationString)"
                }
            }
        }
    }
}

struct MapViewContainer: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedLocation: String
    @ObservedObject var viewModel: MapViewModel  // Ensure this is used correctly in the body

    var body: some View {
        VStack {
            MapView(selectedLocation: $selectedLocation, viewModel: viewModel)
            Button("Close") {
                // Safely unwrap the selectedCoordinate
                if let coordinate = viewModel.selectedCoordinate {
                    selectedLocation = "\(coordinate.latitude),\(coordinate.longitude)"
                }
                presentationMode.wrappedValue.dismiss()
            }
            .padding()
            .foregroundColor(.white)
            .background(Color.blue)
            .cornerRadius(10)
        }
    }
}



