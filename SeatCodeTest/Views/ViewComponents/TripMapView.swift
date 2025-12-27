//
//  TripMapView.swift
//  SeatCode
//
//  Created by Angel Docampo on 19/12/25.
//

import SwiftUI
import MapKit
import CoreLocation

struct TripMapView: View {
    @State var viewModel: TripManagerViewModel
    @State private var locationManager = LocationManager()
    @State private var mapPosition: MapCameraPosition = .automatic
    
    var body: some View {
        Map(position: $mapPosition) {
            
            if let selectedTrip = viewModel.selectedTrip {
                // MARK: Route polyline
                MapPolyline(coordinates: viewModel.selectedTripCoordinates)
                    .stroke(.blue, lineWidth: 4)
                
                // MARK: Origin marker
                Annotation(
                    "Start",
                    coordinate: selectedTrip.origin.point.coordinate,
                    anchor: .bottom
                ) {
                    Image(systemName: "location.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                        .background(Color.white)
                        .clipShape(Circle())
                }
                
                // MARK: Destination marker
                Annotation(
                    "End",
                    coordinate: selectedTrip.destination.point.coordinate,
                    anchor: .bottom
                ) {
                    Image(systemName: "location.circle.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                        .background(Color.white)
                        .clipShape(Circle())
                }
                
                // MARK:  Stop markers
                ForEach(selectedTrip.stops.compactMap { stop -> (Stop, CLLocationCoordinate2D)? in
                    guard let coordinate = stop.coordinate else { return nil }
                    return (stop, coordinate)
                }, id: \.0.id) { stop, coordinate in
                    Annotation(
                        "Stop \(stop.id)",
                        coordinate: coordinate,
                        anchor: .center
                    ) {
                        Button {
                            viewModel.selectStop(stopId: Int(stop.id), from: selectedTrip)
                        } label: {
                            Circle()
                                .fill(.orange)
                                .frame(width: 20, height: 20)
                                .overlay {
                                    Circle()
                                        .stroke(.white, lineWidth: 2)
                                }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        .onChange(of: viewModel.selectedTrip?.id) { _, _ in
            // Update map position when selected trip changes
            mapPosition = .region(viewModel.mapRegion)
        }
        .onAppear {
            // Set initial position
            mapPosition = .region(viewModel.mapRegion)
            
            // Request location permission for the user location button
            locationManager.requestLocationPermission()
        }
        .alert("Location Access", isPresented: .constant(locationManager.errorMessage != nil)) {
            Button("Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) {
                locationManager.errorMessage = nil
            }
        } message: {
            Text(locationManager.errorMessage ?? "")
        }
    }
    
    private func statusColor(for status: TripStatus) -> Color {
        switch status {
        case .ongoing:
            return .green
        case .scheduled:
            return .blue
        case .finalized:
            return .gray
        case .cancelled:
            return .red
        }
    }
}

#Preview {
    let viewModel = TripManagerViewModel()
    
    TripMapView(viewModel: viewModel)
}
