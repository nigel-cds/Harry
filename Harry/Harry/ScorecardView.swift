import SwiftUI

enum TotalsMode: String, CaseIterable, Identifiable {
    case coursePar = "Course Par"
    case myHandicap = "My Handicap"

    var id: String { rawValue }
}

struct ScorecardView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var totalsMode: TotalsMode = .coursePar

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

                HStack(spacing: 0) {
                    Text(course.name).bold()
                    Text("   Par: \(course.par)   MyPar: \(course.par + strokesReceived)(\(strokesReceived))")
                }
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
                .padding(.leading, 16)
                .padding(.trailing, 16)
                
                VStack(spacing: 12) {

                    let front9 = Array(holes.prefix(9))
                    let back9 = Array(holes[9...17])
                    let full = Array(holes.prefix(18))

                    HStack {
                        Text("Stableford total")
                            .frame(width: 160, alignment: .leading)

                        Spacer()

                        Text("\(totalStablefordPoints(for: front9))")
                            .frame(width: 55, alignment: .trailing)

                        Text("\(totalStablefordPoints(for: back9))")
                            .frame(width: 55, alignment: .trailing)

                        Text("\(totalStablefordPoints(for: full))")
                            .frame(width: 55, alignment: .trailing)
                    }

                    HStack {
                        Text(totalsMode == .coursePar ? "Over / under Par" : "Over / under Handicap")
                            .frame(width: 160, alignment: .leading)

                        Spacer()

                        Text(formatted(total: totalPlusMinus(for: front9)))
                            .frame(width: 55, alignment: .trailing)

                        Text(formatted(total: totalPlusMinus(for: back9)))
                            .frame(width: 55, alignment: .trailing)

                        Text(formatted(total: totalPlusMinus(for: full)))
                            .frame(width: 55, alignment: .trailing)
                    }
                    
                    HStack {
                        Text("Birdie/+")
                            .frame(width: 160, alignment: .leading)

                        Spacer()

                        Text("\(totalBirdyOrBetter(for: front9))")
                            .frame(width: 55, alignment: .trailing)

                        Text("\(totalBirdyOrBetter(for: back9))")
                            .frame(width: 55, alignment: .trailing)

                        Text("\(totalBirdyOrBetter(for: full))")
                            .frame(width: 55, alignment: .trailing)
                    }

                    HStack {
                        Text("Par")
                            .frame(width: 160, alignment: .leading)

                        Spacer()

                        Text("\(totalPars(for: front9))")
                            .frame(width: 55, alignment: .trailing)

                        Text("\(totalPars(for: back9))")
                            .frame(width: 55, alignment: .trailing)

                        Text("\(totalPars(for: full))")
                            .frame(width: 55, alignment: .trailing)
                    }

                    HStack {
                        Text("Bogey")
                            .frame(width: 160, alignment: .leading)

                        Spacer()

                        Text("\(totalBogeys(for: front9))")
                            .frame(width: 55, alignment: .trailing)

                        Text("\(totalBogeys(for: back9))")
                            .frame(width: 55, alignment: .trailing)

                        Text("\(totalBogeys(for: full))")
                            .frame(width: 55, alignment: .trailing)
                    }

                    HStack {
                        Text("Boogey")
                            .frame(width: 160, alignment: .leading)

                        Spacer()

                        Text("\(totalBogeysPlus(for: front9))")
                            .frame(width: 55, alignment: .trailing)

                        Text("\(totalBogeysPlus(for: back9))")
                            .frame(width: 55, alignment: .trailing)

                        Text("\(totalBogeysPlus(for: full))")
                            .frame(width: 55, alignment: .trailing)
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

    // Calculate total over / under par, using course par or my par
    func totalPlusMinus(for holesSubset: [Hole]) -> Int {
        switch totalsMode {
        case .coursePar:
            return totalPlusMinusCourse(for: holesSubset)
        case .myHandicap:
            return totalPlusMinusMyPar(for: holesSubset)
        }
    }
    func totalPlusMinusCourse(for holesSubset: [Hole]) -> Int {
        holesSubset.reduce(0) { $0 + ($1.strokes - $1.par) }
    }
    func totalPlusMinusMyPar(for holesSubset: [Hole]) -> Int {
        holesSubset.reduce(0) { $0 + ($1.strokes - $1.par - $1.strokesGiven) }
    }

    // Calculate Birdie or better, using course par or my par
    func totalBirdyOrBetter(for holesSubset: [Hole]) -> Int {
        switch totalsMode {
        case .coursePar:
            return totalBirdyOrBetterCourse(for: holesSubset)
        case .myHandicap:
            return totalBirdyOrBetterMyPar(for: holesSubset)
        }
    }
    func totalBirdyOrBetterCourse(for holesSubset: [Hole]) -> Int {
        holesSubset.filter { $0.strokes < $0.par }.count
    }
    func totalBirdyOrBetterMyPar(for holesSubset: [Hole]) -> Int {
        holesSubset.filter { $0.strokes < ($0.par + $0.strokesGiven) }.count
    }

    // Calculate number of pars, using course par or my par
    func totalPars(for holesSubset: [Hole]) -> Int {
        switch totalsMode {
        case .coursePar:
            return totalParsCourse(for: holesSubset)
        case .myHandicap:
            return totalParsMyPar(for: holesSubset)
        }
    }
    func totalParsCourse(for holesSubset: [Hole]) -> Int {
        holesSubset.filter { $0.strokes == $0.par }.count
    }
    func totalParsMyPar(for holesSubset: [Hole]) -> Int {
        holesSubset.filter { $0.strokes == ($0.par + $0.strokesGiven) }.count
    }

    // Calculate number of bogeys, using course par or my par
    func totalBogeys(for holesSubset: [Hole]) -> Int {
        switch totalsMode {
        case .coursePar:
            return totalBogeysCourse(for: holesSubset)
        case .myHandicap:
            return totalBogeysMyPar(for: holesSubset)
        }
    }
    func totalBogeysCourse(for holesSubset: [Hole]) -> Int {
        holesSubset.filter { $0.strokes == ($0.par + 1)}.count
    }
    func totalBogeysMyPar(for holesSubset: [Hole]) -> Int {
        holesSubset.filter { $0.strokes == ($0.par + $0.strokesGiven + 1) }.count
    }

    // Calculate number of worse than bogeys, using course par or my par
    func totalBogeysPlus(for holesSubset: [Hole]) -> Int {
        switch totalsMode {
        case .coursePar:
            return totalBogeysPlusCourse(for: holesSubset)
        case .myHandicap:
            return totalBogeysPlusMyPar(for: holesSubset)
        }
    }
    func totalBogeysPlusCourse(for holesSubset: [Hole]) -> Int {
        holesSubset.filter { $0.strokes > ($0.par + 1)}.count
    }
    func totalBogeysPlusMyPar(for holesSubset: [Hole]) -> Int {
        holesSubset.filter { $0.strokes > ($0.par + $0.strokesGiven + 1) }.count
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
