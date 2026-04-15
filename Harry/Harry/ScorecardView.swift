import SwiftUI

struct ScorecardView: View {
    @Environment(\.dismiss) private var dismiss

    let playerName: String
    let competitionName: String
    let course: Course
    @State var holes: [Hole]
    let strokesReceived: Int
    let handicap: Double

    @State private var currentHoleIndex = 0
    @State private var showSavedAlert = false
    @State private var showSaveError = false

    var body: some View {
        let hole = holes[currentHoleIndex]

        VStack(spacing: 16) {
            VStack(spacing: 4) {
                Text("Strokes Received: \(strokesReceived)")
                    .font(.headline)

                Text("Handicap: \(handicap, specifier: "%.1f")   Slope: \(course.slope)   SSS: \(course.sss)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Divider()

            VStack(spacing: 16) {
                Text("Hole \(hole.number) of \(holes.count)")
                    .font(.title2)
                    .bold()

                VStack(spacing: 12) {
                    HStack {
                        Text("Par")
                        Spacer()
                        Text("\(hole.par)")
                    }

                    HStack {
                        Text("H'cap")
                        Spacer()
                        Text("\(hole.handicap)")
                    }

                    HStack {
                        Text("Strokes")
                        Spacer()

                        HStack(spacing: 10) {
                            Button {
                                if holes[currentHoleIndex].strokes > 1 {
                                    holes[currentHoleIndex].strokes -= 1
                                }
                            } label: {
                                Text("−")
                                    .font(.title)
                                    .frame(width: 36, height: 36)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(6)
                            }

                            Text("\(hole.strokes)")
                                .font(.title2)
                                .frame(minWidth: 30)

                            Button {
                                if holes[currentHoleIndex].strokes < 15 {
                                    holes[currentHoleIndex].strokes += 1
                                }
                            } label: {
                                Text("+")
                                    .font(.title)
                                    .frame(width: 36, height: 36)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(6)
                            }
                        }
                    }

                    Divider()

                    HStack {
                        Text("Strokes Given")
                        Spacer()
                        Text("\(strokesGiven(for: hole))")
                    }

                    HStack {
                        Text("+/- Par")
                        Spacer()
                        Text(formatted(total: plusMinusPar(for: hole)))
                    }

                    HStack {
                        Text("+/- My Par")
                        Spacer()
                        Text(formatted(total: plusMinusMyPar(for: hole)))
                    }

                    HStack {
                        Text("Stableford")
                        Spacer()
                        Text("\(stablefordPoints(for: hole))")
                    }

                    HStack {
                        Text("Stableford Total")
                        Spacer()
                        Text("\(totalStablefordPoints())")
                    }
                }
                .font(.headline)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }

            Divider()

            VStack(spacing: 8) {
                Text("Totals (to hole \(hole.number))")
                    .font(.headline)

                HStack {
                    Text("Over/Under Par")
                    Spacer()
                    Text(formatted(total: totalPlusMinusPar()))
                }

                HStack {
                    Text("Over/Under My Par")
                    Spacer()
                    Text(formatted(total: totalPlusMinusMyPar()))
                }

                HStack {
                    Text("Stableford Total")
                    Spacer()
                    Text("\(totalStablefordPoints())")
                }
            }

            Spacer()

            HStack {
                Button("Previous") {
                    if currentHoleIndex > 0 {
                        currentHoleIndex -= 1
                    }
                }
                .disabled(currentHoleIndex == 0)

                Spacer()

                if currentHoleIndex == holes.count - 1 {
                    Button("Finish & Save") {
                        saveRound()
                    }
                } else {
                    Button("Next") {
                        currentHoleIndex += 1
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding()
        .navigationTitle("Harry")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Round Saved", isPresented: $showSavedAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your round has been saved to the local database.")
        }
        .alert("Could not save round", isPresented: $showSaveError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please try again.")
        }
    }

    func strokesGiven(for hole: Hole) -> Int {
        let base = strokesReceived / 18
        let remainder = strokesReceived % 18
        return base + (hole.handicap <= remainder ? 1 : 0)
    }

    func plusMinusPar(for hole: Hole) -> Int {
        hole.strokes - hole.par
    }

    func plusMinusMyPar(for hole: Hole) -> Int {
        hole.strokes - hole.par - strokesGiven(for: hole)
    }

    func totalPlusMinusPar() -> Int {
        holes.prefix(currentHoleIndex + 1)
            .reduce(0) { $0 + ($1.strokes - $1.par) }
    }

    func totalPlusMinusMyPar() -> Int {
        holes.prefix(currentHoleIndex + 1)
            .reduce(0) { $0 + ($1.strokes - $1.par - strokesGiven(for: $1)) }
    }

    func stablefordPoints(for hole: Hole) -> Int {
        let netRelativeToPar = hole.strokes - hole.par - strokesGiven(for: hole)
        return max(0, 2 - netRelativeToPar)
    }

    func totalStablefordPoints() -> Int {
        holes.prefix(currentHoleIndex + 1)
            .reduce(0) { $0 + stablefordPoints(for: $1) }
    }

    func formatted(total: Int) -> String {
        if total > 0 { return "+\(total)" }
        if total < 0 { return "\(total)" }
        return "0"
    }

    private func saveRound() {
        let ok = SQLiteManager.shared.insertPlayedRound(
            playerName: playerName,
            competitionName: competitionName,
            courseId: course.id,
            courseName: course.name,
            handicap: handicap,
            slope: course.slope,
            sss: course.sss,
            strokesReceived: strokesReceived,
            holes: holes
        )

        if ok {
            showSavedAlert = true
        } else {
            showSaveError = true
        }
    }
}

#Preview {
    NavigationStack {
        ScorecardView(
            playerName: "Harry",
            competitionName: "",
            course: Course(
                id: 1,
                name: "Default Course",
                slope: 113,
                sss: 72,
                holes: [Hole].defaultHoles()
            ),
            holes: [Hole].defaultHoles(),
            strokesReceived: 18,
            handicap: 18.0
        )
    }
}
