import SwiftUI
import Foundation

struct RecentRoundRow: View {
    @State private var totalsMode: TotalsMode = .coursePar

    let round: PlayedRound

    var body: some View {
        
        let stableford = RoundCalculations.totalStablefordPoints(for: round.holes)
        let front9Stableford = RoundCalculations.totalStablefordPoints(for: Array(round.holes.prefix(9)))
        let back9Stableford = RoundCalculations.totalStablefordPoints(for: Array(round.holes.suffix(9)))

        let overUnder = RoundCalculations.totalPlusMinus(for: round.holes, totalsMode: totalsMode)
        let front9OverUnder = RoundCalculations.totalPlusMinus(for: Array(round.holes.prefix(9)), totalsMode: totalsMode)
        let back9OverUnder = RoundCalculations.totalPlusMinus(for: Array(round.holes.suffix(9)), totalsMode: totalsMode)

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
                        "\(RoundCalculations.formatted(total: overUnder)) (\(RoundCalculations.formatted(total: front9OverUnder))/\(RoundCalculations.formatted(total: back9OverUnder)))",
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
