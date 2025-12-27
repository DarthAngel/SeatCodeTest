//
//  TripCardView.swift
//  SeatCode
//
//  Created by Angel Docampo on 19/12/25.
//

import SwiftUI

struct TripCardView: View {
    let trip: Trip
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header with status and description
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(trip.description)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                        
                        HStack {
                            Circle()
                                .fill(statusColor)
                                .frame(width: 8, height: 8)
                            
                            Text(trip.status.displayName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(trip.stops.count) stops")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                                .font(.title2)
                        }
                    }
                }
                
                // Driver information
                HStack {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.title3)
                    
                    Text(trip.driverName)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                
                // Route information
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "location.circle")
                                .foregroundColor(.green)
                                .font(.caption)
                            
                            Text(trip.origin.address)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        
                        HStack {
                            Image(systemName: "location.circle.fill")
                                .foregroundColor(.red)
                                .font(.caption)
                            
                            Text(trip.destination.address)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                }
                
                // Time information
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Start: \(trip.startTime.formatTime())")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text("End: \(trip.endTime.formatTime())")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var statusColor: Color {
        switch trip.status {
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
    let sampleTrip = Trip(
        id: 1,
        description: "Barcelona to Martorell",
        driverName: "Alberto Morales",
        route: "sdq{Fc}iLj@zR|W~TryCzvC",
        status: .ongoing,
        origin: Location(
            address: "Metropolis:lab, Barcelona",
            point: Point(latitude: 41.38074, longitude: 2.18594)
        ),
        stops: [
            Stop(id: 1, point: Point(latitude: 41.4, longitude: 2.2)),
            Stop(id: 2, point: Point(latitude: 41.45, longitude: 2.1))
        ],
        destination: Location(
            address: "SEAT HQ, Martorell",
            point: Point(latitude: 41.49958, longitude: 1.90307)
        ),
        endTime: "2018-12-18T09:00:00.000Z",
        startTime: "2018-12-18T08:00:00.000Z"
    )
    
    VStack {
        TripCardView(trip: sampleTrip, isSelected: false) {
            print("Trip tapped")
        }
        
        TripCardView(trip: sampleTrip, isSelected: true) {
            print("Trip tapped")
        }
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
