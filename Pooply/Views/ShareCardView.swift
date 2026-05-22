//
//  ShareCardView.swift
//  Pooply
//
//  GO Club-inspired share cards with generated mascot art
//

import SwiftUI
import FirebaseAnalytics

// MARK: - Share Card Sheet

struct ShareCardSheet: View {
    let score: Int
    let goodCount: Int
    let totalCount: Int
    let streak: Int
    let timeframe: String
    @EnvironmentObject var userViewModel: UserViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var selectedStyle = 0
    @State private var appeared = false
    @Namespace private var dotAnim

    private let cards: [ShareCardData] = ShareCardData.all

    var body: some View {
        ZStack {
            Color(hex: "#080C12").ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: - Top bar
                HStack {
                    // Timeframe pills
                    HStack(spacing: 6) {
                        Text("Today")
                            .font(Theme.Fonts.captionBold())
                            .foregroundStyle(Color.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.15))
                            .clipShape(Capsule())

                        Text("Overall")
                            .font(Theme.Fonts.captionBold())
                            .foregroundStyle(Color.white.opacity(0.4))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                    }
                    .padding(4)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())

                    Spacer()

                    Button(action: {
                        Theme.Haptics.light()
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color.white.opacity(0.5))
                            .frame(width: 34, height: 34)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, Theme.Spacing.screenHorizontal)
                .padding(.top, 12)

                // MARK: - Card carousel
                TabView(selection: $selectedStyle) {
                    ForEach(cards.indices, id: \.self) { index in
                        ShareCard(
                            data: cards[index],
                            score: score,
                            goodCount: goodCount,
                            totalCount: totalCount,
                            streak: streak
                        )
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxHeight: .infinity)

                // MARK: - Page dots
                HStack(spacing: 8) {
                    ForEach(cards.indices, id: \.self) { i in
                        Capsule()
                            .fill(i == selectedStyle ? Color.white : Color.white.opacity(0.2))
                            .frame(width: i == selectedStyle ? 24 : 8, height: 8)
                            .animation(Theme.Animation.spring, value: selectedStyle)
                    }
                }
                .padding(.bottom, 20)

                // MARK: - Share button
                Button(action: {
                    Theme.Haptics.medium()
                    Analytics.logEvent("share_card_shared", parameters: [
                        "style": cards[selectedStyle].name
                    ])
                    shareCurrentCard()
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .bold))
                        Text("Share")
                            .font(Theme.Fonts.bodyBold())
                    }
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: 200)
                    .frame(height: 54)
                    .background(Theme.Colors.primary)
                    .clipShape(Capsule())
                }
                .buttonStyle(BouncyButtonStyle())
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            Analytics.logEvent("share_modal_opened", parameters: nil)
        }
    }

    @MainActor
    private func shareCurrentCard() {
        let card = ShareCard(
            data: cards[selectedStyle],
            score: score,
            goodCount: goodCount,
            totalCount: totalCount,
            streak: streak
        )

        let renderer = ImageRenderer(content: card.frame(width: 360, height: 520))
        renderer.scale = 3.0

        if let image = renderer.uiImage {
            let activityVC = UIActivityViewController(
                activityItems: [image, "Check out my gut health on Pooply!"],
                applicationActivities: nil
            )

            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                var topVC = rootVC
                while let presented = topVC.presentedViewController {
                    topVC = presented
                }
                topVC.present(activityVC, animated: true)
            }
        }
    }
}

// MARK: - Share Card Data

struct ShareCardData {
    let name: String
    let imageName: String
    let watermark: String
    let accentColor: Color

    static let all: [ShareCardData] = [
        ShareCardData(name: "Epic", imageName: "share_epic", watermark: "HOLY\nSH*T", accentColor: Color(hex: "#3B82F6")),
        ShareCardData(name: "Streak", imageName: "share_streak", watermark: "ON A\nROLL", accentColor: Color(hex: "#00E89D")),
        ShareCardData(name: "Vibrant", imageName: "share_vibrant", watermark: "GUT\nCHECK", accentColor: Color(hex: "#B388FF")),
        ShareCardData(name: "Golden", imageName: "share_golden", watermark: "REGU\nLAR", accentColor: Color(hex: "#FFB800")),
        ShareCardData(name: "Clean", imageName: "share_clean", watermark: "CLEA\nN", accentColor: Color(hex: "#7B61FF")),
    ]
}

// MARK: - Share Card (the actual rendered card)

struct ShareCard: View {
    let data: ShareCardData
    let score: Int
    let goodCount: Int
    let totalCount: Int
    let streak: Int

    private var dateString: String {
        let f = DateFormatter()
        f.dateFormat = "E, d MMM ''yy"
        return f.string(from: Date())
    }

    var body: some View {
        ZStack {
            // Generated mascot image as full background
            Image(data.imageName)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Bottom gradient fade for readability
            VStack {
                Spacer()
                LinearGradient(
                    colors: [.clear, Color.black.opacity(0.85)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 260)
            }

            // Giant watermark text (GO Club style, behind metrics)
            VStack {
                Text(data.watermark)
                    .font(.system(size: 100, weight: .black, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.08))
                    .lineSpacing(-24)
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.5)
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 16)
            .padding(.top, 16)
            .clipped()

            // Metrics overlay
            VStack(alignment: .leading, spacing: 0) {
                Spacer()

                // Date + Pooply badge
                HStack {
                    Text(dateString)
                        .font(Theme.Fonts.bodyBold())
                        .foregroundStyle(Color.white.opacity(0.9))

                    Spacer()

                    HStack(spacing: 5) {
                        Image("lee")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                            .clipShape(Circle())
                        Text("Pooply")
                            .font(Theme.Fonts.label())
                            .foregroundStyle(Color.white.opacity(0.7))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.12))
                    .clipShape(Capsule())
                }
                .padding(.bottom, 10)

                // Big score
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text("\(score)")
                        .font(.system(size: 68, weight: .black, design: .rounded))
                        .foregroundStyle(Color.white)
                    Text("%")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.5))
                        .offset(y: -6)
                }

                Text("Gut Score")
                    .font(Theme.Fonts.bodyBold())
                    .foregroundStyle(data.accentColor)
                    .padding(.bottom, 14)

                // Stat row
                HStack(spacing: 0) {
                    StatPill(value: "\(goodCount)", label: "Good", unit: nil)
                    StatPill(value: "\(totalCount)", label: "Total", unit: nil)
                    StatPill(value: "\(streak)", label: "Streak", unit: "d")
                }
            }
            .padding(22)
        }
        .frame(height: 500)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

// MARK: - Stat Pill

private struct StatPill: View {
    let value: String
    let label: String
    let unit: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white)
                if let unit = unit {
                    Text(unit)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.4))
                }
            }
            Text(label)
                .font(Theme.Fonts.label(10))
                .foregroundStyle(Color.white.opacity(0.4))
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Preview

#Preview("Share Cards") {
    ShareCardSheet(
        score: 86,
        goodCount: 12,
        totalCount: 15,
        streak: 5,
        timeframe: "This Week"
    )
    .environmentObject(
        UserViewModel(
            user: User(name: "Brandon", age: 25, weight: 160, gender: "male"),
            withDummyData: true
        )
    )
    .environmentObject(SubscriptionService.shared)
}
