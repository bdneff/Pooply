//
//  AnimatedBenefitsIntro.swift
//  Pooply
//
//  Auto-playing animated intro. Mesh-gradient bg (matches Home), an oversized
//  donut gauge that sweeps to 100%, pops once on completion, then hands the
//  stage over to a sequence of two-word benefit pairs. No buttons. Auto-jumps
//  to .profile when the last pair finishes.
//

import SwiftUI
import FirebaseAnalytics

struct AnimatedBenefitsIntro: View {
    @ObservedObject var state: OnboardingState

    // MARK: - Animation state

    @State private var gaugeFill: CGFloat = 0
    @State private var gaugeDone: Bool = false      // true exactly when the ring reaches 1.0
    @State private var ringPulse: Bool = false      // one-shot punch when the gauge tops out
    @State private var glow: Bool = false           // soft glow that comes alive after the sweep
    @State private var showPair: Bool = false       // gates ANY pair text — only true after gauge completes
    @State private var pairIndex: Int = 0
    @State private var hasAdvanced: Bool = false

    // MARK: - Tunables

    private let gaugeDuration: Double = 1.4          // full ring sweep
    private let pauseBeforeText: Double = 0.35       // breathing room between gauge complete & text in
    private let pairVisibleDuration: Double = 0.85
    private let pairCrossfadeDuration: Double = 0.28
    private let ringOuterDiameter: CGFloat = 300
    private let ringThickness: CGFloat = 24

    private let pairs: [(first: String, second: String)] = [
        ("Smarter", "Gut"),
        ("Cleaner", "Data"),
        ("Better", "Insights"),
        ("Daily", "Wins"),
        ("You", "First")
    ]

    var body: some View {
        ZStack {
            // Same mesh background as Home — way more interesting than a flat fill.
            MeshBackground()

            // Center stage: gauge ring + pair text on top of it.
            ZStack {
                gaugeRing

                // Text never appears until gauge completes AND the brief pause passes.
                pairText
                    .opacity(showPair ? 1 : 0)
                    .scaleEffect(showPair ? 1 : 0.92)
                    .animation(.spring(response: 0.45, dampingFraction: 0.78), value: showPair)
                    .animation(.spring(response: 0.45, dampingFraction: 0.78), value: pairIndex)
            }
            .frame(width: ringOuterDiameter, height: ringOuterDiameter)
        }
        .onAppear(perform: runSequence)
    }

    // MARK: - Gauge Ring

    private var gaugeRing: some View {
        ZStack {
            // Soft outer glow — only switches on once the gauge completes.
            Circle()
                .fill(Theme.Colors.iconBlue400.opacity(glow ? 0.35 : 0))
                .frame(width: ringOuterDiameter + 60, height: ringOuterDiameter + 60)
                .blur(radius: 28)
                .animation(.easeOut(duration: 0.5), value: glow)

            // Empty track — visible from the start so the sweep has somewhere to go.
            Circle()
                .stroke(
                    Color.white.opacity(0.55),
                    style: StrokeStyle(lineWidth: ringThickness, lineCap: .round)
                )
                .frame(width: ringOuterDiameter, height: ringOuterDiameter)

            // Filled sweep — gauge fill from 12 o'clock clockwise.
            Circle()
                .trim(from: 0, to: gaugeFill)
                .stroke(
                    AngularGradient(
                        colors: [
                            Theme.Colors.iconBlue300,
                            Theme.Colors.iconBlue400,
                            Theme.Colors.iconBlue500,
                            Theme.Colors.iconBlue400
                        ],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: ringThickness, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: ringOuterDiameter, height: ringOuterDiameter)

            // One-shot punch when the gauge tops out.
            Circle()
                .stroke(Theme.Colors.iconBlue400.opacity(ringPulse ? 0 : 0.5), lineWidth: 4)
                .frame(width: ringOuterDiameter, height: ringOuterDiameter)
                .scaleEffect(ringPulse ? 1.18 : 1.0)
                .animation(.easeOut(duration: 0.55), value: ringPulse)
        }
        .shadow(color: Theme.Colors.iconBlue500.opacity(0.22), radius: 24, x: 0, y: 10)
    }

    // MARK: - Pair text (only visible after gauge completes)

    private var pairText: some View {
        let pair = pairs[min(pairIndex, pairs.count - 1)]
        return VStack(spacing: 0) {
            Text(pair.first)
                .font(.custom("PlusJakartaSans-ExtraBold", size: 40))
                .foregroundStyle(Theme.Colors.iconBlue500)
                .tracking(-0.5)
            Text(pair.second)
                .font(.custom("PlusJakartaSans-ExtraBold", size: 40))
                .foregroundStyle(Theme.Colors.neutral900)
                .tracking(-0.5)
        }
        .multilineTextAlignment(.center)
        // Keyed by pairIndex so SwiftUI animates index changes.
        .id("pair-\(pairIndex)")
    }

    // MARK: - Sequence

    private func runSequence() {
        Analytics.logEvent("onboarding_animated_intro", parameters: nil)

        // Reset (in case the view reappears).
        gaugeFill = 0
        gaugeDone = false
        ringPulse = false
        glow = false
        showPair = false
        pairIndex = 0
        hasAdvanced = false

        // 1) Sweep the gauge fully around.
        withAnimation(.easeInOut(duration: gaugeDuration)) {
            gaugeFill = 1
        }

        // 2) When the gauge tops out: pulse + glow on.
        DispatchQueue.main.asyncAfter(deadline: .now() + gaugeDuration) {
            gaugeDone = true
            glow = true
            ringPulse = true

            // 3) Hold for a beat, THEN start showing text.
            DispatchQueue.main.asyncAfter(deadline: .now() + pauseBeforeText) {
                showPair = true
                cyclePair(from: 0)
            }
        }
    }

    private func cyclePair(from index: Int) {
        guard index < pairs.count else {
            // Done — fade text out and auto-advance.
            withAnimation(.easeOut(duration: pairCrossfadeDuration)) {
                showPair = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + pairCrossfadeDuration) {
                advanceToProfile()
            }
            return
        }

        pairIndex = index

        DispatchQueue.main.asyncAfter(deadline: .now() + pairVisibleDuration + pairCrossfadeDuration) {
            cyclePair(from: index + 1)
        }
    }

    private func advanceToProfile() {
        guard !hasAdvanced else { return }
        hasAdvanced = true
        state.next()
    }
}

// MARK: - Preview

#Preview {
    AnimatedBenefitsIntro(state: OnboardingState())
}
