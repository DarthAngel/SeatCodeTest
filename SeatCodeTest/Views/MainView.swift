//
//  MainView.swift
//  SeatCodeTest
//
//  Created by Angel Docampo on 18/12/25.
//

import SwiftUI
import MapKit
import UIKit

struct MainView: View {
    
    // MARK: PROPERTIES
    
    @State private var viewModel = TripManagerViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // Map View - takes up 40% of screen
                    TripMapView(viewModel: viewModel)
                        .frame(height: geometry.size.height * 0.4)
                        .clipped()
                    
                    // Trip List - takes up remaining 60% of screen
                    TripListView(viewModel: viewModel)
                        .frame(maxHeight: .infinity)
                        .background(Color(.systemGroupedBackground))
                }
            }
            .navigationTitle("Trip Manager")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.showingContactForm = true
                    } label: {
                        Image(systemName: "exclamationmark.bubble")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingContactForm) {
                ContactFormView(contactService: viewModel.contactService)
            }
            .overlay {
                // Stop detail popup
                if viewModel.showingStopPopup {
                    if let stopDetail = viewModel.selectedStopDetail {
                        StopDetailPopup(
                            stopDetail: stopDetail,
                            isPresented: viewModel.showingStopPopup
                        ) {
                            viewModel.showingStopPopup = false
                            viewModel.selectedStopDetail = nil
                        }
                    } else {
                        EmptyStopDetailPopup(
                            isPresented: viewModel.showingStopPopup
                        ) {
                            viewModel.showingStopPopup = false
                        }
                    }
                }
            }
        }
        .onAppear {
            // Request notification permission for app badge
            viewModel.contactService.requestNotificationPermission()
        }
    }
}

#Preview {
    MainView()
}
