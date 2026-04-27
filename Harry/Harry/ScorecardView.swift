import SwiftUI

struct ScorecardView: View {
    @Environment(\.dismiss) private var dismiss

    let roundId: Int64
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
                        Text("H'cap")
                        Spacer()
                        Text("\(hole.handicap)")
                    }

                    HStack {
                        Text("Par")
                        Spacer()
                        Text("\(hole.par)")
                    }

                    HStack {
                        Text("Strokes Given")
                        Spacer()
                        Text(hole.strokesGiven, format: .number)
                    }

                    HStack {
                        Text("Strokes")
                        Spacer()

                        HStack(spacing: 10) {
                            Button {
                                if holes[currentHoleIndex].strokes > 1 {
                                    holes[currentHoleIndex].strokes -= 1
                                    persistHoleChange(at: currentHoleIndex)
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
                                    persistHoleChange(at: currentHoleIndex)
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
                        Text("Over / under Par")
                        Spacer()
                        Text(formatted(total: plusMinusPar(for: hole)))
                    }

                    HStack {
                        Text("Over / under My Par")
                        Spacer()
                        Text(formatted(total: plusMinusMyPar(for: hole)))
                    }

                    HStack {
                        Text("Stableford")
                        Spacer()
                        Text("\(stablefordPoints(for: hole))")
                    }

                }
                .font(.headline)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }

            Divider()

            VStack(spacing: 8) {
                Text("Totals")
                    .font(.headline)

                VStack(spacing: 12) {
                    if currentHoleIndex >= 9 {
                        let front9 = Array(holes.prefix(9))
                        let backSoFar = Array(holes[9...currentHoleIndex])
                        let fullSoFar = Array(holes.prefix(currentHoleIndex + 1))

                        HStack {
                            Text("")
                                .frame(width: 160, alignment: .leading)

                            Spacer()

                            Text("1-9")
                                .frame(width: 55, alignment: .trailing)

                            Text("10-\(hole.number)")
                                .frame(width: 55, alignment: .trailing)

                            Text("Total")
                                .frame(width: 55, alignment: .trailing)
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                        HStack {
                            Text("Over / under Par")
                                .frame(width: 160, alignment: .leading)

                            Spacer()

                            Text(formatted(total: totalPlusMinusPar(for: front9)))
                                .frame(width: 55, alignment: .trailing)

                            Text(formatted(total: totalPlusMinusPar(for: backSoFar)))
                                .frame(width: 55, alignment: .trailing)

                            Text(formatted(total: totalPlusMinusPar(for: fullSoFar)))
                                .frame(width: 55, alignment: .trailing)
                        }

                        HStack {
                            Text("Over / under My Par")
                                .frame(width: 160, alignment: .leading)

                            Spacer()

                            Text(formatted(total: totalPlusMinusMyPar(for: front9)))
                                .frame(width: 55, alignment: .trailing)

                            Text(formatted(total: totalPlusMinusMyPar(for: backSoFar)))
                                .frame(width: 55, alignment: .trailing)

                            Text(formatted(total: totalPlusMinusMyPar(for: fullSoFar)))
                                .frame(width: 55, alignment: .trailing)
                        }

                        HStack {
                            Text("Stableford total")
                                .frame(width: 160, alignment: .leading)

                            Spacer()

                            Text("\(totalStablefordPoints(for: front9))")
                                .frame(width: 55, alignment: .trailing)

                            Text("\(totalStablefordPoints(for: backSoFar))")
                                .frame(width: 55, alignment: .trailing)

                            Text("\(totalStablefordPoints(for: fullSoFar))")
                                .frame(width: 55, alignment: .trailing)
                        }
                    } else {
                        HStack {
                            Text("")
                                .frame(width: 160, alignment: .leading)

                            Spacer()

                            Text("")
                                .frame(width: 55, alignment: .trailing)

                            Text("")
                                .frame(width: 55, alignment: .trailing)

                            Text("1-\(hole.number)")
                                .frame(width: 55, alignment: .trailing)
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                        HStack {
                            Text("Over / under Par")
                            Spacer()
                            Text(formatted(total: totalPlusMinusPar()))
                        }

                        HStack {
                            Text("Over / under My Par")
                            Spacer()
                            Text(formatted(total: totalPlusMinusMyPar()))
                        }

                        HStack {
                            Text("Stableford Total")
                            Spacer()
                            Text("\(totalStablefordPoints())")
                        }
                    }
                }
                .font(.headline)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
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
                    Button("Finish") {
                        finishRound()
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
        .onAppear {
            holes = SQLiteManager.shared.fetchPlayedRoundHoles(roundId: roundId)
        }
    }

    func front9Holes() -> [Hole] {
        Array(holes.prefix(9))
    }

    func back9HolesToCurrent() -> [Hole] {
        guard currentHoleIndex >= 9 else { return [] }
        return Array(holes[9...currentHoleIndex])
    }

    func totalPlusMinusPar(for holesSubset: [Hole]) -> Int {
        holesSubset.reduce(0) { $0 + ($1.strokes - $1.par) }
    }

    func totalPlusMinusMyPar(for holesSubset: [Hole]) -> Int {
        holesSubset.reduce(0) { $0 + ($1.strokes - $1.par - $1.strokesGiven) }
    }

    func totalStablefordPoints(for holesSubset: [Hole]) -> Int {
        holesSubset.reduce(0) { $0 + stablefordPoints(for: $1) }
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
        hole.strokes - hole.par - hole.strokesGiven
    }

    func totalPlusMinusPar() -> Int {
        holes.prefix(currentHoleIndex + 1)
            .reduce(0) { $0 + ($1.strokes - $1.par) }
    }

    func totalPlusMinusMyPar() -> Int {
        holes.prefix(currentHoleIndex + 1)
            .reduce(0) { $0 + ($1.strokes - $1.par - $1.strokesGiven) }
    }

    func stablefordPoints(for hole: Hole) -> Int {
        let netRelativeToPar = hole.strokes - hole.par - hole.strokesGiven
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

    private func persistHoleChange(at index: Int) {
        let hole = holes[index]

        let ok = SQLiteManager.shared.updatePlayedRoundHole(
            roundId: roundId,
            holeNumber: hole.number,
            strokes: hole.strokes
        )

        if !ok {
            showSaveError = true
        }
    }

    private func finishRound() {
        showSavedAlert = true
    }
}

#Preview {
    NavigationStack {
        ScorecardView(
            roundId: 1,
            playerName: "Harry",
            competitionName: "",
            course: Course(
                id: 1,
                name: "Default Course",
                slope: 113,
                sss: 72,
                par: 72,
                holes: [Hole].defaultHoles()
            ),
            holes: [Hole].defaultHoles(),
            strokesReceived: 18,
            handicap: 18.0
        )
    }
}
