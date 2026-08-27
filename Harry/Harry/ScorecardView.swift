import SwiftUI

enum TotalsMode: String, CaseIterable, Identifiable {
    case coursePar = "Course Par"
    case myHandicap = "My Handicap"

    var id: String { rawValue }
}

enum ScorecardDisplayMode: String, CaseIterable, Identifiable {
    case singleHole = "Single Hole"
    case allHoles = "18 Holes"

    var id: String { rawValue }
}

struct ScorecardView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var totalsMode: TotalsMode = .coursePar
    @State private var displayMode: ScorecardDisplayMode = .singleHole

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
        VStack(spacing: 12) {
            headerView

            Picker("Scorecard view", selection: $displayMode) {
                ForEach(ScorecardDisplayMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            Divider()

            if holes.isEmpty {
                Spacer()
                ProgressView()
                Spacer()
            } else {
                if displayMode == .singleHole {
                    singleHoleView
                } else {
                    allHolesView
                }

                Divider()

                totalsView

                Spacer(minLength: 0)

                if displayMode == .singleHole {
                    singleHoleNavigation
                } else {
                    allHolesNavigation
                }
            }
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

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 4) {
            HStack(spacing: 0) {
                Text(course.name).bold()
                Text("   Par: \(course.par)   MyPar: \(course.par + strokesReceived)(\(strokesReceived))")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
    }

    // MARK: - Existing single-hole view

    private var singleHoleView: some View {
        let hole = holes[currentHoleIndex]

        return VStack(spacing: 16) {
            Text("Hole \(hole.number) of \(holes.count) - \(hole.isPlayed ? "Played" : "Not Played")")
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
                    strokeEditor(for: currentHoleIndex, large: true)
                }

                Divider()

                HStack {
                    Text("Over / under Par")
                    Spacer()
                    Text(RoundCalculations.formatted(
                        total: RoundCalculations.plusMinusPar(for: hole)
                    ))
                }

                HStack {
                    Text("Over / under My Par")
                    Spacer()
                    Text(RoundCalculations.formatted(
                        total: RoundCalculations.plusMinusMyPar(for: hole)
                    ))
                }

                HStack {
                    Text("Stableford")
                    Spacer()
                    Text("\(RoundCalculations.stablefordPoints(for: hole))")
                }
            }
            .font(.headline)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }

    // MARK: - New 18-hole view

    private var allHolesView: some View {
        VStack(spacing: 0) {
            allHolesHeaderRow

            Divider()

            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(spacing: 0) {
                    ForEach(holes.indices, id: \.self) { index in
                        allHolesRow(index: index)

                        if index != holes.indices.last {
                            Divider()
                        }
                    }
                }
            }
            .frame(height: 300)
        }
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var allHolesHeaderRow: some View {
        HStack(spacing: 2) {
            tableHeader("Hole", width: 34)
            tableHeader("H'cap", width: 38)
            tableHeader("Par", width: 30)
            tableHeader("Given", width: 40)
            tableHeader("Strokes", width: 100)
            tableHeader("+/- Par", width: 46)
            tableHeader("Stfd", width: 38)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 7)
        .font(.caption)
        .fontWeight(.semibold)
        .foregroundColor(.secondary)
    }

    private func allHolesRow(index: Int) -> some View {
        let hole = holes[index]

        return HStack(spacing: 2) {
            tableText("\(hole.number)", width: 34)
            tableText("\(hole.handicap)", width: 38)
            tableText("\(hole.par)", width: 30)
            tableText("\(hole.strokesGiven)", width: 40)

            strokeEditor(for: index, large: false)
                .frame(width: 100)

            tableText(
                hole.isPlayed
                    ? RoundCalculations.formatted(
                        total: RoundCalculations.plusMinusPar(for: hole)
                    )
                    : "–",
                width: 46
            )

            tableText(
                hole.isPlayed
                    ? "\(RoundCalculations.stablefordPoints(for: hole))"
                    : "–",
                width: 38
            )
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 3)
        .font(.subheadline)
        .contentShape(Rectangle())
        .onTapGesture {
            currentHoleIndex = index
        }
    }

    private func tableHeader(_ text: String, width: CGFloat) -> some View {
        Text(text)
            .frame(width: width, alignment: .center)
    }

    private func tableText(_ text: String, width: CGFloat) -> some View {
        Text(text)
            .frame(width: width, alignment: .center)
            .monospacedDigit()
    }

    // MARK: - Stroke editor shared by both views

    private func strokeEditor(for index: Int, large: Bool) -> some View {
        HStack(spacing: large ? 10 : 4) {
            Button {
                changeStrokes(at: index, by: -1)
            } label: {
                Text("−")
                    .font(large ? .title : .headline)
                    .frame(
                        width: large ? 36 : 28,
                        height: large ? 36 : 28
                    )
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(6)
            }
            .buttonStyle(.plain)

            Text("\(holes[index].strokes)")
                .font(large ? .title2 : .subheadline)
                .fontWeight(.semibold)
                .monospacedDigit()
                .frame(minWidth: large ? 30 : 24)

            Button {
                changeStrokes(at: index, by: 1)
            } label: {
                Text("+")
                    .font(large ? .title : .headline)
                    .frame(
                        width: large ? 36 : 28,
                        height: large ? 36 : 28
                    )
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(6)
            }
            .buttonStyle(.plain)
        }
    }

    private func changeStrokes(at index: Int, by amount: Int) {
        let newValue = holes[index].strokes + amount

        guard newValue >= 1, newValue <= 15 else {
            return
        }

        holes[index].strokes = newValue
        holes[index].isPlayed = true
        persistHoleChange(at: index)
    }

    // MARK: - Totals (unchanged in both scorecard views)

    private var totalsView: some View {
        VStack(spacing: 8) {
            Picker("Totals mode", selection: $totalsMode) {
                ForEach(TotalsMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)

            HStack(alignment: .firstTextBaseline) {
                Text("Totals")
                    .font(.headline)
                    .frame(width: 160, alignment: .leading)

                Spacer()

                Text("Front")
                    .frame(width: 55, alignment: .trailing)

                Text("Back")
                    .frame(width: 55, alignment: .trailing)

                Text("Total")
                    .frame(width: 55, alignment: .trailing)
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            .padding(.horizontal, 16)

            VStack(spacing: 12) {
                let front9 = Array(holes.prefix(9))
                let back9 = holes.count > 9 ? Array(holes.dropFirst(9).prefix(9)) : []
                let full = Array(holes.prefix(18))

                HStack {
                    Text("Stableford total")
                        .frame(width: 160, alignment: .leading)

                    Spacer()

                    Text("\(RoundCalculations.totalStablefordPoints(for: front9))")
                        .frame(width: 55, alignment: .trailing)

                    Text("\(RoundCalculations.totalStablefordPoints(for: back9))")
                        .frame(width: 55, alignment: .trailing)

                    Text("\(RoundCalculations.totalStablefordPoints(for: full))")
                        .frame(width: 55, alignment: .trailing)
                }

                HStack {
                    Text(totalsMode == .coursePar ? "Over / under Par" : "Over / under Handicap")
                        .frame(width: 160, alignment: .leading)

                    Spacer()

                    Text(RoundCalculations.formatted(
                        total: RoundCalculations.totalPlusMinus(for: front9, totalsMode: totalsMode)
                    ))
                    .frame(width: 55, alignment: .trailing)

                    Text(RoundCalculations.formatted(
                        total: RoundCalculations.totalPlusMinus(for: back9, totalsMode: totalsMode)
                    ))
                    .frame(width: 55, alignment: .trailing)

                    Text(RoundCalculations.formatted(
                        total: RoundCalculations.totalPlusMinus(for: full, totalsMode: totalsMode)
                    ))
                    .frame(width: 55, alignment: .trailing)
                }

                HStack {
                    Text("Birdie/+")
                        .frame(width: 160, alignment: .leading)

                    Spacer()

                    Text("\(RoundCalculations.totalBirdyOrBetter(for: front9, totalsMode: totalsMode))")
                        .frame(width: 55, alignment: .trailing)

                    Text("\(RoundCalculations.totalBirdyOrBetter(for: back9, totalsMode: totalsMode))")
                        .frame(width: 55, alignment: .trailing)

                    Text("\(RoundCalculations.totalBirdyOrBetter(for: full, totalsMode: totalsMode))")
                        .frame(width: 55, alignment: .trailing)
                }

                HStack {
                    Text("Par")
                        .frame(width: 160, alignment: .leading)

                    Spacer()

                    Text("\(RoundCalculations.totalPars(for: front9, totalsMode: totalsMode))")
                        .frame(width: 55, alignment: .trailing)

                    Text("\(RoundCalculations.totalPars(for: back9, totalsMode: totalsMode))")
                        .frame(width: 55, alignment: .trailing)

                    Text("\(RoundCalculations.totalPars(for: full, totalsMode: totalsMode))")
                        .frame(width: 55, alignment: .trailing)
                }

                HStack {
                    Text("Bogey")
                        .frame(width: 160, alignment: .leading)

                    Spacer()

                    Text("\(RoundCalculations.totalBogeys(for: front9, totalsMode: totalsMode))")
                        .frame(width: 55, alignment: .trailing)

                    Text("\(RoundCalculations.totalBogeys(for: back9, totalsMode: totalsMode))")
                        .frame(width: 55, alignment: .trailing)

                    Text("\(RoundCalculations.totalBogeys(for: full, totalsMode: totalsMode))")
                        .frame(width: 55, alignment: .trailing)
                }

                HStack {
                    Text("Bogey+")
                        .frame(width: 160, alignment: .leading)

                    Spacer()

                    Text("\(RoundCalculations.totalBogeysPlus(for: front9, totalsMode: totalsMode))")
                        .frame(width: 55, alignment: .trailing)

                    Text("\(RoundCalculations.totalBogeysPlus(for: back9, totalsMode: totalsMode))")
                        .frame(width: 55, alignment: .trailing)

                    Text("\(RoundCalculations.totalBogeysPlus(for: full, totalsMode: totalsMode))")
                        .frame(width: 55, alignment: .trailing)
                }
            }
            .font(.headline)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }

    // MARK: - Navigation

    private var singleHoleNavigation: some View {
        HStack {
            Button("Previous") {
                if currentHoleIndex > 0 {
                    currentHoleIndex -= 1
                }
            }
            .disabled(currentHoleIndex == 0)

            Spacer()

            Button("Skip") {
                holes[currentHoleIndex].isPlayed = false
                persistHoleChange(at: currentHoleIndex)

                if currentHoleIndex < holes.count - 1 {
                    currentHoleIndex += 1
                }
            }

            Spacer()

            if currentHoleIndex == holes.count - 1 {
                Button("Finish") {
                    finishRound()
                }
            } else {
                Button("Next") {
                    holes[currentHoleIndex].isPlayed = true
                    persistHoleChange(at: currentHoleIndex)
                    currentHoleIndex += 1
                }
            }
        }
        .padding(.horizontal)
    }

    private var allHolesNavigation: some View {
        HStack {
            Spacer()

            Button("Finish") {
                finishRound()
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Persistence

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

        SQLiteManager.shared.updatePlayedRoundHolePlayedStatus(
            roundId: roundId,
            holeNumber: hole.number,
            isPlayed: hole.isPlayed
        )
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
