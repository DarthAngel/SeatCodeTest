//
//  ReportsListView.swift
//  SeatCode
//
//  Created by Angel Docampo on 20/12/25.
//

import SwiftUI

struct ReportsListView: View {
    @Environment(\.dismiss) private var dismiss
    let contactService: ContactService
    
    var body: some View {
        NavigationView {
            List {
                if contactService.reports.isEmpty {
                    ContentUnavailableView(
                        "No Reports",
                        systemImage: "doc.text",
                        description: Text("No reports have been submitted yet.")
                    )
                } else {
                    ForEach(contactService.reports) { report in
                        ReportRowView(report: report)
                    }
                    .onDelete { indexSet in
                        contactService.deleteReports(at: indexSet)
                    }
                }
            }
            .navigationTitle("All Reports")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                if !contactService.reports.isEmpty {
                    ToolbarItem(placement: .primaryAction) {
                        EditButton()
                    }
                }
            }
        }
    }
}

struct ReportRowView: View {
    let report: ContactReport
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(report.name) \(report.surname)")
                    .font(.headline)
                
                Spacer()
                
                Text(report.reportDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Image(systemName: "envelope")
                    .foregroundColor(.secondary)
                    .font(.caption)
                
                Text(report.email)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let phone = report.phone, !phone.isEmpty {
                    Spacer()
                    
                    Image(systemName: "phone")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    
                    Text(phone)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(report.description)
                .font(.body)
                .lineLimit(3)
                .padding(.top, 4)
            
            HStack {
                Spacer()
                Text(report.reportDate, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let service = ContactService()
    service.reports = [
        ContactReport(
            name: "John",
            surname: "Doe",
            email: "john.doe@example.com",
            phone: "123-456-7890",
            reportDate: Date(),
            description: "This is a sample report description that shows how the report will look in the list view."
        ),
        ContactReport(
            name: "Jane",
            surname: "Smith",
            email: "jane.smith@example.com",
            phone: nil,
            reportDate: Date().addingTimeInterval(-86400),
            description: "Another sample report with a longer description to test the line limit functionality."
        )
    ]
    return ReportsListView(contactService: service)
}