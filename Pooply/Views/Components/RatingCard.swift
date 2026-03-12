//
//  RatingCard.swift
//  Pooply
//
//  Emoji rating card with re-ask logic for App Store review prompt
//

import SwiftUI
import StoreKit

struct RatingCard: View {
    @Binding var isPresented: Bool

    @AppStorage("lastRatingValue") private var lastRatingValue: Int = 0
    @AppStorage("lastRatingLogCount") private var lastRatingLogCount: Int = 0
    @AppStorage("ratingPromptCount") private var ratingPromptCount: Int = 0

    @State private var showCard = false
    @State private var backgroundOpacity: Double = 0
    @State private var selectedRating: Int = 0
    @State private var showThankYou = false

    private let emojis = ["😞", "😕", "😐", "😊", "😍"]
    private let labels = ["Terrible", "Bad", "Okay", "Good", "Love it"]

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(backgroundOpacity)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack {
                Spacer()

                VStack(spacing: Theme.Spacing.lg) {
                    if showThankYou {
                        thankYouContent
                    } else {
                        ratingContent
                    }
                }
                .padding(Theme.Spacing.cardPadding)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.12), radius: 24, x: 0, y: 8)
                )
                .scaleEffect(showCard ? 1 : 0.9)
                .offset(y: showCard ? 0 : 100)
                .opacity(showCard ? 1 : 0)
                .padding(.horizontal, Theme.Spacing.screenHorizontal)
                .padding(.bottom, 120)

                Spacer()
            }
        }
        .onAppear {
            ratingPromptCount += 1
            withAnimation(.easeOut(duration: 0.2)) {
                backgroundOpacity = 0.4
            }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showCard = true
            }
        }
    }

    // MARK: - Rating Content

    private var ratingContent: some View {
        VStack(spacing: Theme.Spacing.lg) {
            VStack(spacing: Theme.Spacing.sm) {
                Text("How are you liking Pooply?")
                    .font(Theme.Fonts.heading())
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Your feedback helps us improve")
                    .font(Theme.Fonts.caption())
                    .foregroundStyle(Theme.Colors.textTertiary)
            }

            // Emoji buttons
            HStack(spacing: Theme.Spacing.md) {
                ForEach(0..<5, id: \.self) { index in
                    VStack(spacing: 4) {
                        Button(action: {
                            handleRating(index + 1)
                        }) {
                            Text(emojis[index])
                                .font(.system(size: 36))
                                .scaleEffect(selectedRating == index + 1 ? 1.2 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedRating)
                        }

                        Text(labels[index])
                            .font(Theme.Fonts.micro())
                            .foregroundStyle(Theme.Colors.textTertiary)
                    }
                }
            }
        }
    }

    // MARK: - Thank You Content

    private var thankYouContent: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "heart.fill")
                .font(.system(size: 40))
                .foregroundStyle(Theme.Colors.primary)

            Text("Thanks for your feedback!")
                .font(Theme.Fonts.heading())
                .foregroundStyle(Theme.Colors.textPrimary)
                .multilineTextAlignment(.center)
        }
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Actions

    private func handleRating(_ rating: Int) {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        selectedRating = rating
        lastRatingValue = rating

        if rating >= 4 {
            // Good rating — trigger App Store review prompt
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                    SKStoreReviewController.requestReview(in: scene)
                }
                dismiss()
            }
        } else {
            // Low rating — show thank you, no store prompt
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showThankYou = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                dismiss()
            }
        }
    }

    private func dismiss() {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
            showCard = false
            backgroundOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            isPresented = false
        }
    }

    // MARK: - Rating Schedule Logic

    /// Determines whether to show the rating card based on log count
    static func shouldShowRating(logCount: Int) -> Bool {
        let lastRating = UserDefaults.standard.integer(forKey: "lastRatingValue")
        let lastRatingLogCount = UserDefaults.standard.integer(forKey: "lastRatingLogCount")
        let promptCount = UserDefaults.standard.integer(forKey: "ratingPromptCount")

        // Max 2 prompts ever
        if promptCount >= 2 { return false }

        // Never re-ask if they gave >= 4
        if lastRating >= 4 { return false }

        // First ask: after 1st log (excitement moment)
        if lastRating == 0 && logCount >= 1 && lastRatingLogCount == 0 {
            UserDefaults.standard.set(logCount, forKey: "lastRatingLogCount")
            return true
        }

        // Re-ask: after 10th log (they're committed)
        if lastRating > 0 && lastRating < 4 && logCount >= 10 && lastRatingLogCount < 10 {
            UserDefaults.standard.set(logCount, forKey: "lastRatingLogCount")
            return true
        }

        return false
    }
}

// MARK: - Preview

#Preview {
    RatingCard(isPresented: .constant(true))
}
