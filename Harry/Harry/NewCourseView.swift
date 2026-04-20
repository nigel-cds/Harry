//
//  NewCourseView.swift
//  Harry
//
//  Created by Nigel Smith on 14/04/2026.
//

import SwiftUI

struct NewCourseView: View {
    @Environment(\.dismiss) private var dismiss
    
    let onSaved: () -> Void
    
    @State private var errorMessage = ""
    @State private var courseName = ""
    @State private var slope = "123"
    @State private var sss = "70.3"
    @State private var par = ""
    @State private var holes = [Hole].defaultHoles()
    @State private var showError = false
    
    var body: some View {
        Form {
            Section("Course") {
                TextField("Course name", text: $courseName)
                
                TextField("Slope", text: $slope)
                    .keyboardType(.numberPad)
                
                TextField("SSS", text: $sss)
                    .keyboardType(.numbersAndPunctuation)
                
                TextField("Par", text: $par)
                    .keyboardType(.numberPad)
            }
            
            Section("Hole Details") {
                ForEach(holes.indices, id: \.self) { index in
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Hole \(holes[index].number)")
                            .font(.headline)
                        
                        HStack {
                            Text("Par")
                            Spacer()
                            Stepper("", value: $holes[index].par, in: 3...6)
                                .labelsHidden()
                            Text("\(holes[index].par)")
                        }
                        
                        HStack {
                            Text("H'cap")
                            Spacer()
                            Stepper("", value: $holes[index].handicap, in: 1...18)
                                .labelsHidden()
                            Text("\(holes[index].handicap)")
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            
            Section {
                Button("Save Course") {
                    saveCourse()
                }
            }
        }
        .navigationTitle("New Course")
        .alert("Could not save course", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please check the values. The course name must be unique.")
        }
    }
    
    private func saveCourse() {
        let trimmedName = courseName.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedSSS = sss.replacingOccurrences(of: ",", with: ".")
        
        guard !trimmedName.isEmpty else {
            errorMessage = "Course name is required."
            showError = true
            return
        }
        
        guard let slopeValue = Int(slope), slopeValue > 0 else {
            errorMessage = "Slope must be a whole number greater than 0."
            showError = true
            return
        }
        
        guard let sssValue = Double(normalizedSSS), sssValue > 0 else {
            errorMessage = "SSS must be a number greater than 0."
            showError = true
            return
        }
        
        guard let parValue = Int(par), parValue > 0 else {
            errorMessage = "Par must be a whole number greater than 0."
            showError = true
            return
        }
        
        let ok = SQLiteManager.shared.insertCourse(
            name: trimmedName,
            slope: slopeValue,
            sss: sssValue,
            par: parValue,
            holes: holes
        )
        
        if ok {
            onSaved()
            dismiss()
        } else {
            errorMessage = "Could not save course."
            showError = true
        }
    }
}
