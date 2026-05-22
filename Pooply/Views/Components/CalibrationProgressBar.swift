//
//  CalibrationProgressBar.swift
//  Pooply
//
//  Horizontal progress bar for the "Learning Your Gut" calibration phase
//  Shows during the 7-14 day trial period as the AI learns the user's patterns
//

import SwiftUI

struct CalibrationProgressBar: View {
    let currentLogs: Int
    let targetLogs: Int // e.g. 14 for 2-week calibration

    @State private var animatedProgress: CGFloat = 0

    private var progress: CGFloat {
        guard targetLogs > 0 else { return 0 }
        return min(CGFloat(currentLogs) / CGFloat(targetLogs), 1.0)
    }

    private var isComplete: Bool {
        currentLogs >= targetLogs
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Label
            HStack {
                Image(systemName: isComplete ? "checkmark.circle.fill" : "brain.filled.head.profile")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(isComplete ? Theme.Colors.mint : Theme.Colors.primary)

                Text(isComplete ? "Gut Sense calibrated" : "Learning your gut...")
                    .font(Theme.Fonts.captionBold())
                    .foregroundStyle(Theme.Colors.textPrimary)

                Spacer()

                Text("\(currentLogs)/\(targetLogs)")
                    .font(Theme.Fonts.caption())
                    .foregroundStyle(Theme.Colors.textTertiary)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track
                    Capsule()
                        .fill(Theme.Colors.neutral200)
                        .frame(height: 8)

                    // Fill
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: isComplete
                                    ? [Theme.Colors.mint, Theme.Colors.mint.opacity(0.8)]
                                    : [Theme.Colors.primary, Theme.Colors.skyBlue400],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * animatedProgress, height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding(Theme.Spacing.cardPadding)
        .background(Theme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous))
        .cardShadow()
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                animatedProgress = progress
            }
        }
        .onChange(of: currentLogs) { _, _ in
            withAnimation(.easeOut(duration: 0.4)) {
                animatedProgress = progress
            }
        }
    }
}

#Preview("Calibrating") {
    ZStack {
        Theme.Colors.background.ignoresSafeArea()

        VStack(spacing: 20) {
            CalibrationProgressBar(currentLogs: 5, targetLogs: 14)
            CalibrationProgressBar(currentLogs: 14, targetLogs: 14)
        }
        .padding()
    }
}
