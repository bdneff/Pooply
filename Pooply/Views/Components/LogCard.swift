//
//  LogCard.swift
//  Pooply
//
//  Log row card — v5 shows Poop Score (the algo number) as the primary metric.
//  Bristol illustration is kept as a visual element only.
//

import SwiftUI

struct LogCard: View {
    let log: Log

    var body: some View {
        let score = UserViewModel.calculatePoopScoreStatic(for: log)
        let band = bandColor(for: score)

        HStack(spacing: Theme.Spacing.md) {
            // Visual: Bristol illustration in score-band-tinted rounded square
            ZStack {
                RoundedRectangle(cornerRadius: Theme.Radius.small, style: .continuous)
                    .fill(band.opacity(0.18))
                Image(log.type.rawValue)
                    .resizable()
                    .scaledToFit()
                    .padding(8)
            }
            .frame(width: 48, height: 48)

            // Time + day
            VStack(alignment: .leading, spacing: 2) {
                Text(timeString(from: log.timestamp))
                    .font(Theme.Fonts.bodyBold(14))
                    .foregroundStyle(Theme.Colors.espresso)
                Text(dayString(from: log.timestamp))
                    .font(Theme.Fonts.caption(12))
                    .foregroundStyle(Theme.Colors.espressoLight)
            }

            Spacer()

            // Score band + numeric — bar fill scales with score
            VStack(alignment: .trailing, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(score)")
                        .font(Theme.Fonts.bodyBold(18))
                        .foregroundStyle(Theme.Colors.espresso)
                    Text("/100")
                        .font(Theme.Fonts.caption(10))
                        .foregroundStyle(Theme.Colors.espressoLight)
                }
                ScoreBar(score: score, width: 56)
            }
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassSurface(radius: Theme.Radius.large)
    }

    // MARK: - Helpers

    private func bandColor(for score: Int) -> Color {
        if score >= 70 { return Theme.Colors.dataGreen }
        if score >= 40 { return Theme.Colors.dataYellow }
        return Theme.Colors.dataPink
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date).lowercased()
    }

    private func dayString(from date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date)     { return "Today" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f.string(from: date)
    }
}

#Preview {
    LogCard(
        log: Log(
            poopScore: .regular,
            type: .smoothSausage,
            color: .mediumBrown,
            size: .medium,
            bloodPercentage: 0,
            hydrationPercentage: 0.8,
            fiberPercentage: 0.6,
            timestamp: Date(),
            analysis: "Sample log"
        )
    )
    .padding()
    .background(Theme.Colors.cream)
}
