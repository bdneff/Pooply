//
//  GutSenseRing.swift
//  Pooply
//
//  Gut Sense Equilibrium Ring — 3 segments for poop categories
//  Green (regular/good), Purple (loose), Orange (hard)
//  Lee (mascot) centered inside the ring
//

import SwiftUI

struct GutSenseRing: View {
    let regularPercent: CGFloat  // 0.0 - 1.0 proportion of regular logs
    let loosePercent: CGFloat    // 0.0 - 1.0 proportion of loose logs
    let hardPercent: CGFloat     // 0.0 - 1.0 proportion of hard logs

    var size: CGFloat = 240
    var lineWidth: CGFloat = 16

    @State private var animateIn = false

    private var segments: [(value: CGFloat, color: Color)] {
        [
            (regularPercent, Theme.Colors.good),   // green
            (loosePercent,   Theme.Colors.loose),   // purple
            (hardPercent,    Theme.Colors.hard),     // orange/amber
        ]
    }

    var body: some View {
        ZStack {
            // Track ring (subtle)
            Circle()
                .stroke(Theme.Colors.neutral200, lineWidth: lineWidth)
                .frame(width: size, height: size)

            // Segment divider dots
            ForEach(0..<3, id: \.self) { i in
                let angle = cumulativeAngle(upTo: i)
                Circle()
                    .fill(Theme.Colors.background)
                    .frame(width: lineWidth + 4, height: lineWidth + 4)
                    .offset(y: -size / 2)
                    .rotationEffect(.degrees(angle - 90))
            }

            // Colored segments — proportional arcs
            ForEach(0..<segments.count, id: \.self) { i in
                let startTrim = cumulativeTrim(upTo: i)
                let segTrim = segments[i].value * 0.98 // slight gap
                let endTrim = startTrim + (animateIn ? segTrim : 0)

                if segments[i].value > 0 {
                    Circle()
                        .trim(from: startTrim + 0.005, to: max(endTrim - 0.005, startTrim + 0.006))
                        .stroke(
                            segments[i].color,
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: size, height: size)
                        .animation(
                            Theme.Animation.ringDraw.delay(Double(i) * 0.12),
                            value: animateIn
                        )
                }
            }

            // Lee (mascot) in center — BIG
            Image("lee")
                .resizable()
                .scaledToFit()
                .frame(width: size * 0.55, height: size * 0.55)
                .scaleEffect(animateIn ? 1.0 : 0.8)
                .opacity(animateIn ? 1.0 : 0)
                .animation(Theme.Animation.bouncy.delay(0.3), value: animateIn)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animateIn = true
            }
        }
    }

    private func cumulativeTrim(upTo index: Int) -> CGFloat {
        var total: CGFloat = 0
        for i in 0..<index {
            total += segments[i].value * 0.98
        }
        return total
    }

    private func cumulativeAngle(upTo index: Int) -> Double {
        var total: CGFloat = 0
        for i in 0..<index {
            total += segments[i].value
        }
        return Double(total) * 360.0
    }
}

// MARK: - Compact Gut Sense Ring (for widgets/small displays)

struct GutSenseRingCompact: View {
    let score: Int // 0-100 overall gut sense score
    var size: CGFloat = 80

    private var scoreColor: Color {
        switch score {
        case 80...100: return Theme.Colors.mint
        case 60..<80:  return Theme.Colors.amber
        case 40..<60:  return Theme.Colors.peach
        default:       return Theme.Colors.coral
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.Colors.neutral200, lineWidth: 6)

            Circle()
                .trim(from: 0, to: CGFloat(score) / 100.0)
                .stroke(scoreColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))

            Text("\(score)")
                .font(Theme.Fonts.heading())
                .foregroundStyle(Theme.Colors.textPrimary)
        }
        .frame(width: size, height: size)
    }
}

#Preview("Gut Sense Ring") {
    ZStack {
        Theme.Colors.background.ignoresSafeArea()

        VStack(spacing: 32) {
            GutSenseRing(
                regularPercent: 0.65,
                loosePercent: 0.20,
                hardPercent: 0.15
            )

            GutSenseRingCompact(score: 78)
        }
    }
}
