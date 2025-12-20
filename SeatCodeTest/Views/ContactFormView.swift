//
//  ContactFormView.swift
//  SeatCode
//
//  Created by Angel Docampo on 20/12/25.
//

import SwiftUI

struct ContactFormView: View {
    @Environment(\.dismiss) private var dismiss
    @State var contactService: ContactService
    
    @State private var name = ""
    @State private var surname = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var reportDescription = ""
    @State private var reportDate = Date()
    
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingReports = false
    
    private let maxDescriptionLength = 200
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("Name*", text: $name)
                        .textContentType(.givenName)
                    
                    TextField("Surname*", text: $surname)
                        .textContentType(.familyName)
                    
                    TextField("Email*", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    TextField("Phone (Optional)", text: $phone)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                }
                
                Section(header: Text("Report Information")) {
                    DatePicker("Date & Time", selection: $reportDate, displayedComponents: [.date, .hourAndMinute])
                    
                    VStack(alignment: .leading) {
                        Text("Description*")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextEditor(text: $reportDescription)
                            .frame(minHeight: 100)
                            .onChange(of: reportDescription) { _, newValue in
                                if newValue.count > maxDescriptionLength {
                                    reportDescription = String(newValue.prefix(maxDescriptionLength))
                                }
                            }
                        
                        HStack {
                            Spacer()
                            Text("\(reportDescription.count)/\(maxDescriptionLength)")
                                .font(.caption2)
                                .foregroundColor(reportDescription.count > maxDescriptionLength * 9/10 ? .orange : .secondary)
                        }
                    }
                }
                
                Section {
                    Text("All fields marked with * are required")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Button("View previously submitted reports") {
                        showingReports = true
                }

                
            }
            .navigationTitle("Report Issue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") {
                        submitReport()
                    }
                    .disabled(!isFormValid)
                }
            }
            
      
            
        }
        .alert("Report Status", isPresented: $showingAlert) {
            Button("OK") {
                if alertMessage.contains("successfully") {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showingReports) {
            ReportsListView(contactService: contactService)
        }
    
    }
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !surname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        isValidEmail(email) &&
        !reportDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    private func submitReport() {
        guard isFormValid else {
            alertMessage = "Please fill in all required fields correctly."
            showingAlert = true
            return
        }
        
        let report = ContactReport(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            surname: surname.trimmingCharacters(in: .whitespacesAndNewlines),
            email: email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
            phone: phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : phone.trimmingCharacters(in: .whitespacesAndNewlines),
            reportDate: reportDate,
            description: reportDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        contactService.saveReport(report)
        
        alertMessage = "Report submitted successfully! Thank you for your feedback."
        showingAlert = true
    }
}

#Preview {
    ContactFormView(contactService: ContactService())
}
