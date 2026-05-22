//
//  LogCard.swift
//  Pooply
//
//  Log Card — v3 with Bristol scale image in category-colored rounded rect
//

import SwiftUI

struct LogCard: View {
    let log: Log

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Bristol scale image in category-colored rounded rect
            Image(log.type.rawValue)
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .padding(8)
                .background(categoryColor(for: log.poopScore).opacity(0.18))
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small, style: .continuous))

            // Day + time + category
            VStack(alignment: .leading, spacing: 2) {
                Text(log.weekday)
                    .font(Theme.Fonts.bodyBold())
                    .foregroundStyle(Theme.Colors.textOnGlass)

                Text(timeString(from: log.timestamp))
                    .font(Theme.Fonts.caption())
                    .foregroundStyle(Theme.Colors.textOnGlass.opacity(0.55))

                Text(log.poopScore.rawValue.capitalized)
                    .font(Theme.Fonts.caption())
                    .foregroundStyle(categoryColor(for: log.poopScore))
            }

            Spacer()

            // Category badge (replaces dot)
            Text(log.poopScore.rawValue.capitalized)
                .font(Theme.Fonts.label(10))
                .foregroundStyle(categoryColor(for: log.poopScore))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(categoryColor(for: log.poopScore).opacity(0.18))
                .clipShape(Capsule())
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassSurface(radius: Theme.Radius.large)
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
