import SwiftUI

struct ContentView: View {
    @State private var playerName = ""
    @State private var competitionName = ""
    @State private var handicap = "18.0"

    @State private var courses: [Course] = []
    @State private var selectedCourseId: Int64?
    @State private var holes = [Hole].defaultHoles()

    @State private var showNewCourse = false
    @State private var recentRounds: [PlayedRound] = []

    private var selectedCourse: Course? {
        courses.first(where: { $0.id == selectedCourseId })
    }

    private var handicapValue: Double {
        Double(handicap) ?? 0
    }

    private var strokesReceived: Int {
        let slope = selectedCourse?.slope ?? 113
        return max(0, Int(round(handicapValue * Double(slope) / 113.0)))
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
                        }
                    }

                    TextField("Competition name (optional)", text: $competitionName)
                }

                Section("Handicap") {
                    TextField("Handicap", text: $handicap)
                        .keyboardType(.decimalPad)

                    HStack {
                        Text("Slope")
                        Spacer()
                        Text("\(selectedCourse?.slope ?? 113)")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("SSS")
                        Spacer()
                        Text("\(selectedCourse?.sss ?? 72)")
                            .foregroundColor(.secondary)
                    }
                }

                Section("Calculated") {
                    HStack {
                        Text("Strokes received")
                        Spacer()
                        Text("\(strokesReceived)")
                            .fontWeight(.semibold)
                    }
                }

                Section {
                    if let selectedCourse {
                        NavigationLink("Harry") {
                            ScorecardView(
                                playerName: playerName,
                                competitionName: competitionName,
                                course: selectedCourse,
                                holes: holes,
                                strokesReceived: strokesReceived,
                                handicap: handicapValue
                            )
                        }
                        .font(.headline)
                    } else {
                        Text("Select a course first")
                            .foregroundColor(.secondary)
                    }
                }

                if !recentRounds.isEmpty {
                    Section("Recent Rounds") {
                        ForEach(recentRounds.prefix(5)) { round in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(round.courseName)
                                    .font(.headline)
                                Text(round.playerName.isEmpty ? "No player name" : round.playerName)
                                    .foregroundColor(.secondary)
                                Text(round.playedAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
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
        }
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
