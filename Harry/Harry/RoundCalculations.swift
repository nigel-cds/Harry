//
//  RoundCalculations.swift
//  Harry
//
//  Created by Nigel Smith on 22/05/2026.
//

import Foundation

enum RoundCalculations {
    // Calculate total over / under par, using course par or my par
    static func totalPlusMinus(for holesSubset: [Hole], totalsMode: TotalsMode) -> Int {
        let played = playedHoles(from: holesSubset)
        switch totalsMode {
        case .coursePar:
            return totalPlusMinusCourse(for: played)
        case .myHandicap:
            return totalPlusMinusMyPar(for: played)
        }
    }
    static func totalPlusMinusCourse(for holesSubset: [Hole]) -> Int {
        holesSubset.reduce(0) { $0 + ($1.strokes - $1.par) }
    }
    static func totalPlusMinusMyPar(for holesSubset: [Hole]) -> Int {
        holesSubset.reduce(0) { $0 + ($1.strokes - $1.par - $1.strokesGiven) }
    }

    // Calculate Birdie or better, using course par or my par
    static func totalBirdyOrBetter(for holesSubset: [Hole], totalsMode: TotalsMode) -> Int {
        let played = playedHoles(from: holesSubset)
        switch totalsMode {
        case .coursePar:
            return totalBirdyOrBetterCourse(for: played)
        case .myHandicap:
            return totalBirdyOrBetterMyPar(for: played)
        }
    }
    static func totalBirdyOrBetterCourse(for holesSubset: [Hole]) -> Int {
        holesSubset.filter { $0.strokes < $0.par }.count
    }
    static func totalBirdyOrBetterMyPar(for holesSubset: [Hole]) -> Int {
        holesSubset.filter { $0.strokes < ($0.par + $0.strokesGiven) }.count
    }

    // Calculate number of pars, using course par or my par
    static func totalPars(for holesSubset: [Hole], totalsMode: TotalsMode) -> Int {
        let played = playedHoles(from: holesSubset)
        switch totalsMode {
        case .coursePar:
            return totalParsCourse(for: played)
        case .myHandicap:
            return totalParsMyPar(for: played)
        }
    }
    static func totalParsCourse(for holesSubset: [Hole]) -> Int {
        holesSubset.filter { $0.strokes == $0.par }.count
    }
    static func totalParsMyPar(for holesSubset: [Hole]) -> Int {
        holesSubset.filter { $0.strokes == ($0.par + $0.strokesGiven) }.count
    }

    // Calculate number of bogeys, using course par or my par
    static func totalBogeys(for holesSubset: [Hole], totalsMode: TotalsMode) -> Int {
        let played = playedHoles(from: holesSubset)
        switch totalsMode {
        case .coursePar:
            return totalBogeysCourse(for: played)
        case .myHandicap:
            return totalBogeysMyPar(for: played)
        }
    }
    static func totalBogeysCourse(for holesSubset: [Hole]) -> Int {
        holesSubset.filter { $0.strokes == ($0.par + 1)}.count
    }
    static func totalBogeysMyPar(for holesSubset: [Hole]) -> Int {
        holesSubset.filter { $0.strokes == ($0.par + $0.strokesGiven + 1) }.count
    }

    // Calculate number of worse than bogeys, using course par or my par
    static func totalBogeysPlus(for holesSubset: [Hole], totalsMode: TotalsMode) -> Int {
        let played = playedHoles(from: holesSubset)
        switch totalsMode {
        case .coursePar:
            return totalBogeysPlusCourse(for: played)
        case .myHandicap:
            return totalBogeysPlusMyPar(for: played)
        }
    }
    static func totalBogeysPlusCourse(for holesSubset: [Hole]) -> Int {
        holesSubset.filter { $0.strokes > ($0.par + 1)}.count
    }
    static func totalBogeysPlusMyPar(for holesSubset: [Hole]) -> Int {
        holesSubset.filter { $0.strokes > ($0.par + $0.strokesGiven + 1) }.count
    }

    static func totalStablefordPoints(for holesSubset: [Hole]) -> Int {
        let played = playedHoles(from: holesSubset)
        return played.reduce(0) { $0 + stablefordPoints(for: $1) }
    }
    static func stablefordPoints(for hole: Hole) -> Int {
        let netRelativeToPar = hole.strokes - hole.par - hole.strokesGiven
        return max(0, 2 - netRelativeToPar)
    }

    static func strokesGiven(for hole: Hole, strokesReceived : Int) -> Int {
        let base = strokesReceived / 18
        let remainder = strokesReceived % 18
        return base + (hole.handicap <= remainder ? 1 : 0)
    }

    static func plusMinusPar(for hole: Hole) -> Int {
        hole.strokes - hole.par
    }

    static func plusMinusMyPar(for hole: Hole) -> Int {
        hole.strokes - hole.par - hole.strokesGiven
    }

    static func formatted(total: Int) -> String {
        if total > 0 { return "+\(total)" }
        if total < 0 { return "\(total)" }
        return "0"
    }

    static func formattedRoundDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()

        if let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: now),
           date >= oneYearAgo {

            return date.formatted(
                Date.FormatStyle()
                    .day(.twoDigits)
                    .month(.abbreviated)
            )
        } else {
            return date.formatted(
                Date.FormatStyle()
                    .month(.abbreviated)
                    .year(.twoDigits)
            )
        }
    }

    private static func playedHoles(from holes: [Hole]) -> [Hole] {
        holes.filter { $0.isPlayed }
    }
}
