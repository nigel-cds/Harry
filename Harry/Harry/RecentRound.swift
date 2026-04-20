import SwiftUI

struct RecentRoundRow: View {
    let round: PlayedRound

    var body: some View {
        let overUnder = RoundCalculations.totalPlusMinusPar(holes: round.holes)
        let stableford = RoundCalculations.totalStablefordPoints(
            holes: round.holes,
            strokesReceived: round.strokesReceived
        )

        let front9Stableford = RoundCalculations.totalStablefordPointsFront9(
            holes: round.holes,
            strokesReceived: round.strokesReceived
        )
        let back9Stableford = RoundCalculations.totalStablefordPointsBack9(
            holes: round.holes,
            strokesReceived: round.strokesReceived
        )

        let front9OverUnder = RoundCalculations.totalPlusMinusParFront9(holes: round.holes)
        let back9OverUnder = RoundCalculations.totalPlusMinusParBack9(holes: round.holes)

        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(round.courseName)
                    .font(.headline)

                Spacer()

                if !round.competitionName.isEmpty {
                    Text(round.competitionName)
                        .font(.headline)
                }
            }

            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    gridCell("Date", width: 63, align: .leading, isHeader: true)
                    gridCell("Hcp", width: 32, isHeader: true)
                    gridCell("St", width: 30, isHeader: true)
                    gridCell("+/-", width: 114, isHeader: true)
                    gridCell("Pts", width: 89, isHeader: true)
                }

                Divider()

                HStack(spacing: 0) {
                    gridCell(
                        RoundCalculations.formattedRoundDate(round.playedAt),
                        width: 63,
                        align: .leading
                    )

                    gridCell("\(round.handicap, default: "%.1f")", width: 32)
                    gridCell("\(round.strokesReceived)", width: 30)
                    gridCell(
                        "\(RoundCalculations.formatted(overUnder)) (\(RoundCalculations.formatted(front9OverUnder))/\(RoundCalculations.formatted(back9OverUnder)))",
                        width: 114
                    )
                    gridCell(
                        "\(stableford) (\(front9Stableford)/\(back9Stableford))",
                        width: 89
                    )
                }
            }
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .padding(.vertical, 4)
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
            .foregroundColor(.secondary)
            .frame(width: width, alignment: align)
            .padding(.vertical, 6)
    }
}
