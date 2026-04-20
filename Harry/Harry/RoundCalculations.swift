//
//  RoundCalculations.swift
//  Harry
//
//  Created by Nigel Smith on 20/04/2026.
//

import Foundation

enum RoundCalculations {
    static func strokesGiven(for hole: Hole, strokesReceived: Int) -> Int {
        let base = strokesReceived / 18
        let remainder = strokesReceived % 18
        return base + (hole.handicap <= remainder ? 1 : 0)
    }

    static func plusMinusPar(for hole: Hole) -> Int {
        hole.strokes - hole.par
    }

    static func plusMinusMyPar(for hole: Hole, strokesReceived: Int) -> Int {
        hole.strokes - hole.par - strokesGiven(for: hole, strokesReceived: strokesReceived)
    }

    static func totalPlusMinusPar(holes: [Hole]) -> Int {
        holes.reduce(0) { $0 + plusMinusPar(for: $1) }
    }

    static func stablefordPoints(for hole: Hole, strokesReceived: Int) -> Int {
        let netRelativeToPar = hole.strokes - hole.par - strokesGiven(for: hole, strokesReceived: strokesReceived)
        return max(0, 2 - netRelativeToPar)
    }

    static func totalStablefordPoints(holes: [Hole], strokesReceived: Int) -> Int {
        holes.reduce(0) { $0 + stablefordPoints(for: $1, strokesReceived: strokesReceived) }
    }

    static func formatted(_ total: Int) -> String {
        if total > 0 { return "+\(total)" }
        if total < 0 { return "\(total)" }
        return "0"
    }
    static func front9Holes(from holes: [Hole]) -> [Hole] {
        Array(holes.prefix(9))
    }

    static func back9Holes(from holes: [Hole]) -> [Hole] {
        Array(holes.dropFirst(9).prefix(9))
    }

    static func totalStrokes(holes: [Hole]) -> Int {
        holes.reduce(0) { $0 + $1.strokes }
    }

    static func totalPar(holes: [Hole]) -> Int {
        holes.reduce(0) { $0 + $1.par }
    }

    static func totalPlusMinusParFront9(holes: [Hole]) -> Int {
        totalPlusMinusPar(holes: front9Holes(from: holes))
    }

    static func totalPlusMinusParBack9(holes: [Hole]) -> Int {
        totalPlusMinusPar(holes: back9Holes(from: holes))
    }

    static func totalStablefordPointsFront9(holes: [Hole], strokesReceived: Int) -> Int {
        totalStablefordPoints(
            holes: front9Holes(from: holes),
            strokesReceived: strokesReceived
        )
    }

    static func totalStablefordPointsBack9(holes: [Hole], strokesReceived: Int) -> Int {
        totalStablefordPoints(
            holes: back9Holes(from: holes),
            strokesReceived: strokesReceived
        )
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
}
