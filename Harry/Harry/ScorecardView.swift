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

                    if currentHoleIndex >= 9 {

                        Text("1-9")
                            .frame(width: 55, alignment: .trailing)

                        Text("10-\(hole.number)")
                            .frame(width: 55, alignment: .trailing)

                        Text("Total")
                            .frame(width: 55, alignment: .trailing)

                    } else {

                        Text("1-\(hole.number)")
                            .frame(width: 55, alignment: .trailing)
                    }
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.leading, 16)
                .padding(.trailing, 16)
                
                VStack(spacing: 12) {

                    if currentHoleIndex >= 9 {
                        let front9 = Array(holes.prefix(9))
                        let backSoFar = Array(holes[9...currentHoleIndex])
                        let fullSoFar = Array(holes.prefix(currentHoleIndex + 1))

                        HStack {
                            Text(totalsMode == .coursePar ? "Over / under Par" : "Over / under Handicap")
                                .frame(width: 160, alignment: .leading)

                            Spacer()

                            Text(formatted(total: totalPlusMinus(for: front9)))
                                .frame(width: 55, alignment: .trailing)

                            Text(formatted(total: totalPlusMinus(for: backSoFar)))
                                .frame(width: 55, alignment: .trailing)

                            Text(formatted(total: totalPlusMinus(for: fullSoFar)))
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

                        HStack {
                            Text("Birdie+")
                                .frame(width: 160, alignment: .leading)

                            Spacer()

                            Text("\(birdiePlusTotal(for: front9))")
                                .frame(width: 55, alignment: .trailing)

                            Text("\(birdiePlusTotal(for: backSoFar))")
                                .frame(width: 55, alignment: .trailing)

                            Text("\(birdiePlusTotal(for: fullSoFar))")
                                .frame(width: 55, alignment: .trailing)
                        }

                        HStack {
                            Text("Par")
                                .frame(width: 160, alignment: .leading)

                            Spacer()

                            Text("\(parTotal(for: front9))")
                                .frame(width: 55, alignment: .trailing)

                            Text("\(parTotal(for: backSoFar))")
                                .frame(width: 55, alignment: .trailing)

                            Text("\(parTotal(for: fullSoFar))")
                                .frame(width: 55, alignment: .trailing)
                        }

                        HStack {
                            Text("Bogey")
                                .frame(width: 160, alignment: .leading)

                            Spacer()

                            Text("\(bogeyTotal(for: front9))")
                                .frame(width: 55, alignment: .trailing)

                            Text("\(bogeyTotal(for: backSoFar))")
                                .frame(width: 55, alignment: .trailing)

                            Text("\(bogeyTotal(for: fullSoFar))")
                                .frame(width: 55, alignment: .trailing)
                        }

                        HStack {
                            Text("Boogey")
                                .frame(width: 160, alignment: .leading)

                            Spacer()

                            Text("\(doubleBogeyPlusTotal(for: front9))")
                                .frame(width: 55, alignment: .trailing)

                            Text("\(doubleBogeyPlusTotal(for: backSoFar))")
                                .frame(width: 55, alignment: .trailing)

                            Text("\(doubleBogeyPlusTotal(for: fullSoFar))")
                                .frame(width: 55, alignment: .trailing)
                        }
                    } else {

                        HStack {
                            Text(totalsMode == .coursePar ? "Over / under Par" : "Over / under Handicap")
                            Spacer()
                            Text(formatted(total: totalPlusMinus()))
                        }
                        
                        HStack {
                            Text("Stableford Total")
                            Spacer()
                            Text("\(totalStablefordPoints())")
                        }

                        HStack {
                            Text("Birdie+")
                            Spacer()
                            Text("\(birdiePlusTotal())")
                        }

                        HStack {
                            Text("Par")
                            Spacer()
                            Text("\(parTotal())")
                        }

                        HStack {
                            Text("Bogey")
                            Spacer()
                            Text("\(bogeyTotal())")
                        }

                        HStack {
                            Text("Boogey")
                            Spacer()
                            Text("\(doubleBogeyPlusTotal())")
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

    func totalPlusMinus(for holesSubset: [Hole]) -> Int {
        switch totalsMode {
        case .coursePar:
            return totalPlusMinusPar(for: holesSubset)
        case .myHandicap:
            return totalPlusMinusMyPar(for: holesSubset)
        }
    }

    func totalPlusMinus() -> Int {
        totalPlusMinus(for: Array(holes.prefix(currentHoleIndex + 1)))
    }

    func birdiePlusTotal(for holesSubset: [Hole]) -> Int {
        holesSubset.filter { $0.strokes < $0.par }.count
    }

    func parTotal(for holesSubset: [Hole]) -> Int {
        holesSubset.filter { $0.strokes == $0.par }.count
    }

    func bogeyTotal(for holesSubset: [Hole]) -> Int {
        holesSubset.filter { $0.strokes == $0.par + 1 }.count
    }

    func doubleBogeyPlusTotal(for holesSubset: [Hole]) -> Int {
        holesSubset.filter { $0.strokes > $0.par + 1 }.count
    }
    
    func birdiePlusTotal() -> Int {
        birdiePlusTotal(for: Array(holes.prefix(currentHoleIndex + 1)))
    }

    func parTotal() -> Int {
        parTotal(for: Array(holes.prefix(currentHoleIndex + 1)))
    }

    func bogeyTotal() -> Int {
        bogeyTotal(for: Array(holes.prefix(currentHoleIndex + 1)))
    }

    func doubleBogeyPlusTotal() -> Int {
        doubleBogeyPlusTotal(for: Array(holes.prefix(currentHoleIndex + 1)))
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
