//
//  ColorFloodAnimation.swift
//  Pooply
//
//  Color Flood Score Reveal — Pooply's signature animation
//  Concentric soft radial gradients emanate from center like ink in water
//  Score determines the color: greens/golds for great, amber for decent, muted for poor
//

import SwiftUI

struct ColorFloodAnimation: View {
    let score: Int // 0-100
    let isRevealed: Bool

    private let ringCount = 6

    private var scoreColor: Color {
        switch score {
        case 85...100: return Theme.Colors.mint
        case 70..<85:  return Theme.Colors.amber
        case 50..<70:  return Theme.Colors.peach
        default:       return Theme.Colors.neutral400
        }
    }

    private var secondaryColor: Color {
        switch score {
        case 85...100: return Theme.Colors.skyBlue200
        case 70..<85:  return Theme.Colors.skyBlue100
        case 50..<70:  return Theme.Colors.neutral200
        default:       return Theme.Colors.neutral300
        }
    }

    var body: some View {
        ZStack {
            // Background
            Theme.Colors.background.ignoresSafeArea()

            // Concentric flood rings — blurred circles that blend like ink
            ForEach(0..<ringCount, id: \.self) { i in
                let delay = Double(i) * 0.08
                let maxScale: CGFloat = 3.0 + CGFloat(i) * 0.5
                let opacity = 0.25 - (Double(i) * 0.03)

                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                i % 2 == 0 ? scoreColor.opacity(opacity) : secondaryColor.opacity(opacity),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 200
                        )
                    )
                    .scaleEffect(isRevealed ? maxScale : 0.01)
                    .blur(radius: isRevealed ? CGFloat(50 + i * 10) : 0)
                    .animation(
                        .easeOut(duration: 1.2).delay(delay),
                        value: isRevealed
                    )
            }
        }
    }
}

// MARK: - Score Reveal View (full screen overlay)

struct ScoreRevealView: View {
    let score: Int
    let onDismiss: () -> Void

    @State private var isRevealed = false
    @State private var showScore = false
    @State private var displayedScore = 0

    private var scoreLabel: String {
        switch score {
        case 85...100: return "Excellent"
        case 70..<85:  return "Good"
        case 50..<70:  return "Fair"
        case 30..<50:  return "Needs Work"
        default:       return "Poor"
        }
    }

    private var scoreLabelColor: Color {
        switch score {
        case 85...100: return Theme.Colors.mint
        case 70..<85:  return Theme.Colors.amber
        case 50..<70:  return Theme.Colors.peach
        default:       return Theme.Colors.coral
        }
    }

    var body: some View {
        ZStack {
            // Color flood background
            ColorFloodAnimation(score: score, isRevealed: isRevealed)

            // Score content
            VStack(spacing: 16) {
                Spacer()

                // Score circle
                ZStack {
                    Circle()
                        .fill(Theme.Colors.cardBackground)
                        .frame(width: 140, height: 140)
                        .cardShadow()

                    VStack(spacing: 4) {
                        Text("\(displayedScore)")
                            .font(Theme.Fonts.hero(56))
                            .foregroundStyle(Theme.Colors.textPrimary)
                            .contentTransition(.numericText())

                        Text("POOP SCORE")
                            .font(Theme.Fonts.label(10))
                            .foregroundStyle(Theme.Colors.textTertiary)
                            .tracking(1)
                    }
                }
                .scaleEffect(showScore ? 1.0 : 0.5)
                .opacity(showScore ? 1.0 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3), value: showScore)

                // Score label badge
                Text(scoreLabel)
                    .font(Theme.Fonts.bodyBold())
                    .foregroundStyle(scoreLabelColor)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(scoreLabelColor.opacity(0.15))
                    .clipShape(Capsule())
                    .opacity(showScore ? 1.0 : 0)
                    .animation(.easeOut(duration: 0.3).delay(0.8), value: showScore)

                Spacer()

                // Tap to continue
                Text("Tap to continue")
                    .font(Theme.Fonts.caption())
                    .foregroundStyle(Theme.Colors.textTertiary)
                    .opacity(showScore ? 1.0 : 0)
                    .animation(.easeOut(duration: 0.3).delay(1.5), value: showScore)
                    .padding(.bottom, 60)
            }
        }
        .onTapGesture {
            if showScore {
                Theme.Haptics.light()
                onDismiss()
            }
        }
        .onAppear {
            // Trigger flood
            isRevealed = true

            // Show score after brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                showScore = true
                Theme.Haptics.success()

                // Animate score count-up
                animateScoreCountUp()
            }
        }
    }

    private func animateScoreCountUp() {
        let steps = 20
        let interval = 0.03
        for i in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * interval) {
                withAnimation(.easeOut(duration: 0.05)) {
                    displayedScore = Int(Double(score) * Double(i) / Double(steps))
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Color Flood") {
    ScoreRevealView(score: 92, onDismiss: {})
}

#Preview("Color Flood - Medium") {
    ScoreRevealView(score: 72, onDismiss: {})
}

#Preview("Color Flood - Low") {
    ScoreRevealView(score: 35, onDismiss: {})
}
