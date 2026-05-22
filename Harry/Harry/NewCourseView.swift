//
//  NewCourseView.swift
//  Harry
//
//  Created by Nigel Smith on 14/04/2026.
//

import SwiftUI

struct NewCourseView: View {
    @Environment(\.dismiss) private var dismiss
    
    let courseToEdit: Course?
    let onSaved: () -> Void
    
    @State private var courseName = ""
    @State private var slope = ""
    @State private var sss = ""
    @State private var par = ""
    @State private var holes = [Hole].defaultHoles()

    // Need to confirm whether these are still required now that course is editable
    @State private var errorMessage = ""
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
            
            Section("Holes Par H'cap") {

                // Header row
                HStack {
                    Text("Hole")
                        .frame(width: 70, alignment: .leading)

                    Text("Par")
                        .frame(width: 80, alignment: .trailing)

                    Text("H'cap")
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .font(.caption)
                .foregroundColor(.secondary)

                // Data rows
                ForEach(holes.indices, id: \.self) { index in
                    HStack {

                        // Hole number
                        Text("\(holes[index].number)")
                            .font(.headline)
                            .frame(width: 70, alignment: .leading)

                        // Par
                        HStack(spacing: 4) {
                            Stepper("", value: $holes[index].par, in: 3...6)
                                .labelsHidden()

                            Text("\(holes[index].par)")
                                .frame(width: 30, alignment: .trailing)
                        }
                        .frame(width: 80, alignment: .trailing)

                        Spacer()

                        // Handicap
                        HStack(spacing: 4) {
                            Stepper("", value: $holes[index].handicap, in: 1...18)
                                .labelsHidden()

                            Text("\(holes[index].handicap)")
                                .frame(width: 30, alignment: .trailing)
                        }
                        .frame(width: 80, alignment: .trailing)
                    }
                    .padding(.vertical, 4)
                }
            }

            Section {
                Button(courseToEdit == nil ? "Save Course" : "Update Course") {
                    saveCourse()
                }
            }
        }
        .navigationTitle(courseToEdit == nil ? "New Course" : "Edit Course")
        .onAppear {
            if let course = courseToEdit {
                courseName = course.name
                slope = "\(course.slope)"
                sss = "\(course.sss)"
                par = "\(course.par)"
                holes = course.holes
            } else {
                slope = "123"
                sss = "70.3"
                par = ""
                holes = [Hole].defaultHoles()
            }
        }
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
        
        let holesParTotal = holes.reduce(0) { $0 + $1.par }

        guard parValue == holesParTotal else {
            errorMessage = "Course par must equal the total par of all holes. Course par is \(parValue), but holes total \(holesParTotal)."
            showError = true
            return
        }

        let ok: Bool

        if let course = courseToEdit {
            ok = SQLiteManager.shared.updateCourse(
                id: course.id,
                name: trimmedName,
                slope: slopeValue,
                sss: sssValue,
                par: parValue,
                holes: holes
            )
        } else {
            ok = SQLiteManager.shared.insertCourse(
                name: trimmedName,
                slope: slopeValue,
                sss: sssValue,
                par: parValue,
                holes: holes
            )
        }
        
        if ok {
            onSaved()
            dismiss()
        } else {
            errorMessage = "Could not save course."
            showError = true
        }
    }
}
