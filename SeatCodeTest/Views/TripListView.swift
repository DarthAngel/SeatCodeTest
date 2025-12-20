//
//  TripListView.swift
//  SeatCode
//
//  Created by Angel Docampo on 19/12/25.
//

import SwiftUI
import MapKit

struct TripListView: View {
    @ObservedObject var viewModel: TripManagerViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Available trips \(viewModel.trips.count)")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            .padding(.horizontal)
            .padding(.top)
            
            if let errorMessage = viewModel.errorMessage {
                ErrorView(message: errorMessage) {
                    Task {
                        await viewModel.refreshTrips()
                    }
                }
                .padding()
            } else {
                // Trip list
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(viewModel.trips) { trip in
                            TripCardView(
                                trip: trip,
                                isSelected: viewModel.selectedTrip?.id == trip.id
                            ) {
                                if viewModel.selectedTrip?.id == trip.id {
                                    // Deselect if already selected
                                    viewModel.selectedTrip = nil
                                    
                                    // Reset map to show all trips
                                    withAnimation(.easeInOut(duration: 1.0)) {
                                        viewModel.mapRegion = MKCoordinateRegion(
                                            center: CLLocationCoordinate2D(latitude: 41.3851, longitude: 2.1734),
                                            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                                        )
                                    }
                                } else {
                                    // Select new trip
                                    viewModel.selectTrip(trip)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                .refreshable {
                    await viewModel.refreshTrips()
                }
            }
        }
    }
}

struct ErrorView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.exclamationmark")
                .font(.largeTitle)
                .foregroundColor(.orange)
            
            Text("Connection Error")
                .font(.headline)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Retry", action: onRetry)
                .buttonStyle(.bordered)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    let viewModel = TripManagerViewModel()
    
    TripListView(viewModel: viewModel)
}
