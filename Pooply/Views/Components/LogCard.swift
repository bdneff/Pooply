//
//  LogCard.swift
//  Pooply
//
//  Created by Brandon Grossnickle on 9/19/25.
//

import SwiftUI

struct LogCard: View {
    let log: Log
    
    var body: some View {
        HStack(spacing: 12) {
            // Poop type image
            Image(log.type.rawValue)
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
                .padding(8)
                .background(Color(hex: "#e5fff7"))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            // Day + time + category
            VStack(alignment: .leading, spacing: 2) {
                Text(log.weekday) // e.g. "Sunday"
                    .font(Font.custom("Nunito Bold", size: 16))
                    .foregroundStyle(Color(hex: "#1B5E20"))
                Text(timeString(from: log.timestamp)) // e.g. "12:00 p.m."
                    .font(Font.custom("Nunito Regular", size: 14))
                    .foregroundStyle(Color(hex: "#2E7D32"))
                Text(log.poopScore.rawValue.capitalized)
                    .font(Font.custom("Nunito Regular", size: 12))
                    .foregroundStyle(categoryColor(for: log.poopScore))
            }

            Spacer()

            // Category indicator
            Circle()
                .fill(categoryColor(for: log.poopScore))
                .frame(width: 12, height: 12)
        }
        .padding()
        .background(Color(hex: "#e5fff7"))
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
    }

    // MARK: - Helpers

    private func categoryColor(for category: Log.PoopCategory) -> Color {
        switch category {
        case .regular: return Color(hex: "#19b888")
        case .loose: return Color(hex: "#008CFF")
        case .hard: return Color(hex: "#FF7A33")
        }
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a" // 12:00 PM
        return formatter.string(from: date).lowercased() // "12:00 p.m."
    }
}



//#Preview {
//    LogCard()
//}
