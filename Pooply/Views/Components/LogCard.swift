//
//  LogCard.swift
//  Pooply
//
//  Redesigned Log Card - Phase 8
//

import SwiftUI

struct LogCard: View {
    let log: Log

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Poop type image
            Image(log.type.rawValue)
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)
                .padding(8)
                .background(Theme.Colors.tealTint)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small, style: .continuous))

            // Day + time + category
            VStack(alignment: .leading, spacing: 2) {
                Text(log.weekday)
                    .font(Theme.Fonts.bodyBold())
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text(timeString(from: log.timestamp))
                    .font(Theme.Fonts.caption())
                    .foregroundStyle(Theme.Colors.textSecondary)

                Text(log.poopScore.rawValue.capitalized)
                    .font(Theme.Fonts.caption())
                    .foregroundStyle(categoryColor(for: log.poopScore))
            }

            Spacer()

            // Category indicator
            Circle()
                .fill(categoryColor(for: log.poopScore))
                .frame(width: 12, height: 12)
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.large, style: .continuous))
        .cardShadow()
    }

    // MARK: - Helpers

    private func categoryColor(for category: Log.PoopCategory) -> Color {
        switch category {
        case .regular: return Theme.Colors.good
        case .loose: return Theme.Colors.loose
        case .hard: return Theme.Colors.hard
        }
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date).lowercased()
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
    .background(Theme.Colors.background)
}
