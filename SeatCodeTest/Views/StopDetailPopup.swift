//
//  StopDetailPopup.swift
//  SeatCode
//
//  Created by Angel Docampo on 19/12/25.
//

import SwiftUI

struct StopDetailPopup: View {
    let stopDetail: StopDetail?
    let isPresented: Bool
    let onDismiss: () -> Void
    
    var body: some View {
        if isPresented, let stop = stopDetail {
            ZStack {
                // Semi-transparent background
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        onDismiss()
                    }
                
                // Popup content
                VStack(spacing: 16) {
                    // Header
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Stop Information")
                                .font(.headline)
                            
                            Text("Trip ID: \(stop.tripId)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(action: onDismiss) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .font(.title2)
                        }
                    }
                    
                    Divider()
                    
                    // Stop details
                    VStack(spacing: 12) {
                        // Passenger information
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.blue)
                                .font(.title2)
                            
                            VStack(alignment: .leading) {
                                Text("Passenger")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text(stop.userName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            
                            Spacer()
                        }
                        
                        // Location information
                        HStack {
                            Image(systemName: "location.circle.fill")
                                .foregroundColor(.orange)
                                .font(.title2)
                            
                            VStack(alignment: .leading) {
                                Text("Address")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text(stop.address)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .lineLimit(2)
                            }
                            
                            Spacer()
                        }
                        
                        // Time information
                        HStack {
                            Image(systemName: "clock.circle.fill")
                                .foregroundColor(.green)
                                .font(.title2)
                            
                            VStack(alignment: .leading) {
                                Text("Stop Time")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text(stop.stopTime.formatTime())
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            
                            Spacer()
                        }
                        
                        // Price and payment status
                        HStack {
                            Image(systemName: stop.paid ? "creditcard.circle.fill" : "exclamationmark.circle.fill")
                                .foregroundColor(stop.paid ? .green : .red)
                                .font(.title2)
                            
                            VStack(alignment: .leading) {
                                Text("Payment")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    Text(stop.formattedPrice)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    Text(stop.paid ? "• Paid" : "• Unpaid")
                                        .font(.caption)
                                        .foregroundColor(stop.paid ? .green : .red)
                                }
                            }
                            
                            Spacer()
                        }
                        
                        // Coordinates (for debugging/technical info)
                        HStack {
                            Image(systemName: "map.circle.fill")
                                .foregroundColor(.purple)
                                .font(.title2)
                            
                            VStack(alignment: .leading) {
                                Text("Coordinates")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text(String(format: "%.5f, %.5f", stop.point.latitude, stop.point.longitude))
                                    .font(.caption.monospaced())
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(radius: 20)
                .padding()
            }
        }
    }
}

struct EmptyStopDetailPopup: View {
    let isPresented: Bool
    let onDismiss: () -> Void
    
    var body: some View {
        if isPresented {
            ZStack {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        onDismiss()
                    }
                
                VStack(spacing: 16) {
                    HStack {
                        Text("Stop Information")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: onDismiss) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .font(.title2)
                        }
                    }
                    
                    Divider()
                    
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        
                        Text("No stop details available")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("Stop information could not be loaded from the server.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    
                    Spacer()
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(radius: 20)
                .padding()
            }
        }
    }
}

#Preview {
    let sampleStopDetail = StopDetail(
        id: 1,
        stopTime: "2018-12-18T09:00:00.000Z",
        paid: true,
        address: "Ramblas, Barcelona",
        tripId: 1,
        userName: "Manuel Gomez",
        point: Point(latitude: 41.37653, longitude: 2.17924),
        price: 1.5
    )
    
    VStack {
        StopDetailPopup(
            stopDetail: sampleStopDetail,
            isPresented: true
        ) {
            print("Dismissed")
        }
    }
}
