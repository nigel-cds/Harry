import SwiftUI

struct ContentView: View {
    
    @State private var createdRoundId: Int64?
    @State private var goToScorecard = false
    @State private var selectedRecentRound: PlayedRound?

    @State private var playerName = ""
    @State private var competitionName = ""
    @State private var handicap = "18.0"

    @State private var courses: [Course] = []
    @State private var selectedCourseId: Int64?
    @State private var holes = [Hole].defaultHoles()

    @State private var showNewCourse = false
    @State private var recentRounds: [PlayedRound] = []
    @State private var manualStrokes: Int? = nil
    
    private var selectedCourse: Course? {
        courses.first(where: { $0.id == selectedCourseId })
    }

    private var handicapValue: Double {
        let normalized = handicap.replacingOccurrences(of: ",", with: ".")
        return Double(normalized) ?? 0
    }

    private var calculatedStrokes: Int {
        let slope = Double(selectedCourse?.slope ?? 113)
        let courseRating = selectedCourse?.sss ?? 0.0
        let par = Double(selectedCourse?.par ?? 72)

        let playingHandicap = handicapValue * slope / 113.0 + (courseRating - par)
        return max(0, Int(round(playingHandicap)))
    }

    private var strokesReceived: Int {
        manualStrokes ?? calculatedStrokes
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Player") {
                    TextField("Your name", text: $playerName)
                }
                
                Section("Round") {
                    Picker("Course", selection: $selectedCourseId) {
                        Text("Select a course").tag(nil as Int64?)
                        
                        ForEach(courses) { course in
                            Text(course.name).tag(Optional(course.id))
                        }
                        
                        Text("New Course").tag(Optional(Int64(-1)))
                    }
                    .onChange(of: selectedCourseId) { _, newValue in
                        if newValue == -1 {
                            selectedCourseId = nil
                            showNewCourse = true
                        } else if let course = selectedCourse {
                            holes = course.holes
                            manualStrokes = nil
                        }
                    }
                    
                    TextField("Competition name (optional)", text: $competitionName)
                }
                
                Section("Handicap") {
                    HStack {
                        Text("Handicap")
                        Spacer()
                        TextField("Handicap", text: $handicap)
                            .foregroundColor(.secondary)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 120, alignment: .trailing)
                    }
                    
                    HStack {
                        Text("Slope")
                        Spacer()
                        Text("\(selectedCourse?.slope ?? 113)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("SSS")
                        Spacer()
                        Text(String(format: "%.1f", selectedCourse?.sss ?? 72.0))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Par")
                        Spacer()
                        Text("\(selectedCourse?.par ?? 72)")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Calculated") {
                    HStack {
                        Text("Strokes received")
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            TextField(
                                "Strokes",
                                value: Binding(
                                    get: { manualStrokes ?? calculatedStrokes },
                                    set: { manualStrokes = $0 }
                                ),
                                format: .number
                            )
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 80, alignment: .trailing)
                            .fontWeight(.semibold)
                            
                            Text(manualStrokes == nil ? "Auto" : "Manual")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if manualStrokes != nil {
                        Button("Use calculated value") {
                            manualStrokes = nil
                        }
                    }
                }
                
                Section {
                    if let selectedCourse {
                        Button("Harry") {
                            let course = selectedCourse
                            if let roundId = SQLiteManager.shared.insertPlayedRound(
                                playerName: playerName,
                                competitionName: competitionName,
                                courseId: course.id,
                                courseName: course.name,
                                handicap: handicapValue,
                                slope: course.slope,
                                sss: course.sss,
                                par: course.par,
                                strokesReceived: strokesReceived,
                                holes: holes
                            ) {
                                createdRoundId = roundId
                                selectedRecentRound = nil
                                goToScorecard = true
                            } else {
                                print("Failed to create round")
                            }
                        }
                    } else {
                        Text("Select a course first")
                            .foregroundColor(.secondary)
                    }
                }
                .navigationDestination(isPresented: $goToScorecard) {
                    if let round = selectedRecentRound {
                        ScorecardView(
                            roundId: round.id,
                            playerName: round.playerName,
                            competitionName: round.competitionName,
                            course: Course(
                                id: round.courseId,
                                name: round.courseName,
                                slope: round.slope,
                                sss: round.sss,
                                par: round.par,
                                holes: round.holes
                            ),
                            holes: round.holes,
                            strokesReceived: round.strokesReceived,
                            handicap: round.handicap
                        )
                    } else if let roundId = createdRoundId, let selectedCourse {
                        ScorecardView(
                            roundId: roundId,
                            playerName: playerName,
                            competitionName: competitionName,
                            course: selectedCourse,
                            holes: holes,
                            strokesReceived: strokesReceived,
                            handicap: handicapValue
                        )
                    }
                }
                if !recentRounds.isEmpty {
                    Section("Recent Rounds") {
                        ForEach(recentRounds.prefix(5)) { round in
                            Button {
                                selectedRecentRound = round
                                createdRoundId = nil
                                goToScorecard = true
                            } label: {
                                RecentRoundRow(round: round)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle("Harry Setup")
            .sheet(isPresented: $showNewCourse) {
                NavigationStack {
                    NewCourseView {
                        reloadData()
                    }
                }
            }
            .onAppear {
                reloadData()
            }
            .onChange(of: handicap) { _, _ in
                manualStrokes = nil
            }
        }
    }

    @ViewBuilder
    func gridCell(
        _ text: String,
        width: CGFloat,
        align: Alignment = .trailing,
        isHeader: Bool = false
    ) -> some View {
        Text(text)
            .font(isHeader ? .caption.bold() : .subheadline)
            .foregroundColor(isHeader ? .secondary : .primary)
            .frame(width: width, alignment: align)
            .padding(.vertical, 6)
    }
    
    private func reloadData() {
        courses = SQLiteManager.shared.fetchCourses()
        recentRounds = SQLiteManager.shared.fetchPlayedRounds()

        if selectedCourseId == nil, let first = courses.first {
            selectedCourseId = first.id
            holes = first.holes
        } else if let selectedCourse {
            holes = selectedCourse.holes
        }
    }
}

#Preview {
    ContentView()
}
