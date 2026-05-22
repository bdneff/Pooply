//
//  PaywallView.swift
//  Pooply
//
//  Pooply Pro — Premium dark immersive paywall
//

import SwiftUI
import StoreKit
import RevenueCat
import FirebaseAnalytics

// MARK: - Paywall View (Full Screen Cover)

struct PaywallView: View {
    @EnvironmentObject var subscriptionService: SubscriptionService
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPlan: PlanType = .annual
    @State private var isPurchasing = false
    @State private var errorMessage: String?
    @State private var heroAppeared = false

    enum PlanType {
        case monthly, annual
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Dark premium background — solid black with subtle radial warmth
            Theme.Colors.neutral900.ignoresSafeArea()
            RadialGradient(
                colors: [Theme.Colors.electric.opacity(0.10), Color.clear],
                center: .init(x: 0.5, y: 0.15),
                startRadius: 0,
                endRadius: 380
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack(spacing: 0) {
                // Close button
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Color.white.opacity(0.10)))
                    }
                }
                .padding(.horizontal, Theme.Spacing.screenHorizontal)
                .padding(.top, 8)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 24) {
                        heroSection
                            .padding(.top, 12)

                        featuresSection

                        planCardsSection

                        if let error = errorMessage {
                            Text(error)
                                .font(Theme.Fonts.caption())
                                .foregroundStyle(Theme.Colors.coral)
                                .multilineTextAlignment(.center)
                        }

                        footerSection

                        Spacer().frame(height: 120)
                    }
                    .padding(.horizontal, Theme.Spacing.screenHorizontal)
                }
            }

            // Floating CTA with subtle dark fade
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [Theme.Colors.neutral900.opacity(0), Theme.Colors.neutral900],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 36)
                .allowsHitTesting(false)

                Button(action: purchaseSelectedPlan) {
                    HStack(spacing: 10) {
                        if isPurchasing {
                            ProgressView().tint(Theme.Colors.neutral900)
                        } else {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 14, weight: .bold))
                            Text("Upgrade to Pro")
                                .font(Theme.Fonts.bodyBold())
                        }
                    }
                    .foregroundStyle(Theme.Colors.neutral900)
                }
                .elevatedButtonStyle(color: Theme.Colors.electric, height: 58)
                .disabled(isPurchasing)
                .padding(.horizontal, Theme.Spacing.screenHorizontal)
                .padding(.bottom, 24)
                .background(Theme.Colors.neutral900)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            Analytics.logEvent("paywall_shown", parameters: ["source": "upgrade"])
            withAnimation(.spring(response: 0.7, dampingFraction: 0.62).delay(0.1)) {
                heroAppeared = true
            }
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 18) {
            Image("appLogo")
                .resizable()
                .scaledToFill()
                .frame(width: 112, height: 112)
                .clipShape(Circle())
                .padding(5)
                .background(Circle().fill(Color.white))
                .shadow(color: Theme.Colors.electric.opacity(0.25), radius: 22, x: 0, y: 8)
                .scaleEffect(heroAppeared ? 1.0 : 0.7)
                .opacity(heroAppeared ? 1.0 : 0.0)

            HStack(spacing: 6) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 12, weight: .bold))
                Text("PRO")
                    .font(.custom("PlusJakartaSans-ExtraBold", size: 13))
                    .tracking(2)
            }
            .foregroundStyle(Theme.Colors.neutral900)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(Capsule().fill(Theme.Colors.electric))
            .shadow(color: Theme.Colors.electric.opacity(0.35), radius: 10, x: 0, y: 4)

            VStack(spacing: 6) {
                Text("Unlock Your\nGut Intelligence")
                    .font(Theme.Fonts.hero(32))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)

                Text("AI-powered analysis, smarter insights, and personalized health recommendations.")
                    .font(Theme.Fonts.body(15))
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .padding(.horizontal, 8)
            }
        }
    }

    // MARK: - Features

    private var featuresSection: some View {
        VStack(spacing: 10) {
            PaywallFeatureRow(
                icon: "camera.viewfinder",
                title: "Unlimited AI Scans",
                subtitle: "Snap a photo — instant Bristol type, color, hydration & fiber score"
            )
            PaywallFeatureRow(
                icon: "brain.head.profile",
                title: "Smart Insights",
                subtitle: "Trends, patterns, and recommendations tuned to your gut"
            )
            PaywallFeatureRow(
                icon: "chart.line.uptrend.xyaxis",
                title: "Advanced Analytics",
                subtitle: "Detailed health metrics your doctor will love"
            )
            PaywallFeatureRow(
                icon: "bell.badge.fill",
                title: "Early Access",
                subtitle: "First in line for every new feature"
            )
        }
    }

    // MARK: - Plan Cards

    private var planCardsSection: some View {
        VStack(spacing: 10) {
            PaywallPlanCard(
                title: "Annual",
                price: subscriptionService.annualPriceString,
                period: "/year",
                perMonthPrice: "$2.50/mo",
                badge: "SAVE 65%",
                isSelected: selectedPlan == .annual,
                isRecommended: true,
                onTap: { withAnimation(Theme.Animation.snap) { selectedPlan = .annual } }
            )

            PaywallPlanCard(
                title: "Monthly",
                price: subscriptionService.monthlyPriceString,
                period: "/month",
                perMonthPrice: nil,
                badge: nil,
                isSelected: selectedPlan == .monthly,
                isRecommended: false,
                onTap: { withAnimation(Theme.Animation.snap) { selectedPlan = .monthly } }
            )
        }
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(spacing: 8) {
            Button(action: restorePurchases) {
                Text("Restore Purchases")
                    .font(Theme.Fonts.captionBold(13))
                    .foregroundStyle(.white.opacity(0.55))
            }
            .buttonStyle(.plain)

            HStack(spacing: 16) {
                Link("Terms of Service", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                    .font(Theme.Fonts.micro())
                    .foregroundStyle(.white.opacity(0.35))

                Link("Privacy Policy", destination: URL(string: "https://grossyb.github.io/pooply_privacy/")!)
                    .font(Theme.Fonts.micro())
                    .foregroundStyle(.white.opacity(0.35))
            }
        }
    }

    // MARK: - Actions

    private func purchaseSelectedPlan() {
        isPurchasing = true
        errorMessage = nil

        Task {
            do {
                var success = false

                let package: Package? = selectedPlan == .monthly
                    ? subscriptionService.monthlyPackage
                    : subscriptionService.annualPackage

                if let package = package {
                    success = try await subscriptionService.purchase(package)
                } else {
                    let product: StoreKit.Product? = selectedPlan == .monthly
                        ? subscriptionService.monthlyProduct
                        : subscriptionService.annualProduct

                    guard let product = product else {
                        await MainActor.run {
                            isPurchasing = false
                            errorMessage = "Unable to load plans. Please check your connection."
                        }
                        return
                    }
                    success = try await subscriptionService.purchaseStoreProduct(product)
                }

                await MainActor.run {
                    isPurchasing = false
                    if success {
                        Analytics.logEvent("pro_subscribed", parameters: [
                            "plan": selectedPlan == .monthly ? "monthly" : "annual"
                        ])
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    isPurchasing = false
                    errorMessage = "Purchase failed. Please try again."
                }
            }
        }
    }

    private func restorePurchases() {
        isPurchasing = true
        errorMessage = nil

        Task {
            do {
                let success = try await subscriptionService.restorePurchases()
                await MainActor.run {
                    isPurchasing = false
                    if success {
                        dismiss()
                    } else {
                        errorMessage = "No active subscription found."
                    }
                }
            } catch {
                await MainActor.run {
                    isPurchasing = false
                    errorMessage = "Unable to restore. Please try again."
                }
            }
        }
    }
}

// MARK: - Paywall Feature Row (dark theme)

private struct PaywallFeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                Circle().fill(Theme.Colors.electric).frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.Colors.neutral900)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(Theme.Fonts.bodyBold(15))
                    .foregroundStyle(.white)

                Text(subtitle)
                    .font(Theme.Fonts.caption(13))
                    .foregroundStyle(.white.opacity(0.55))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - Paywall Plan Card (dark theme + electric selection)

private struct PaywallPlanCard: View {
    let title: String
    let price: String
    let period: String
    let perMonthPrice: String?
    let badge: String?
    let isSelected: Bool
    let isRecommended: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            Theme.Haptics.medium()
            onTap()
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(Theme.Fonts.subheading(17))
                            .foregroundStyle(.white)

                        if isRecommended {
                            Text("BEST VALUE")
                                .font(Theme.Fonts.label(9))
                                .tracking(0.8)
                                .foregroundStyle(Theme.Colors.neutral900)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Theme.Colors.electric))
                        }

                        if let badge = badge {
                            Text(badge)
                                .font(Theme.Fonts.label(9))
                                .tracking(0.8)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Color.white.opacity(0.18)))
                        }
                    }

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(price)
                            .font(Theme.Fonts.hero(22))
                            .foregroundStyle(.white)
                        Text(period)
                            .font(Theme.Fonts.caption(13))
                            .foregroundStyle(.white.opacity(0.55))
                    }

                    if let perMonth = perMonthPrice {
                        Text(perMonth)
                            .font(Theme.Fonts.captionBold(12))
                            .foregroundStyle(Theme.Colors.electric)
                    }
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(isSelected ? Theme.Colors.electric : Color.white.opacity(0.25), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    if isSelected {
                        Circle().fill(Theme.Colors.electric).frame(width: 14, height: 14)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(isSelected ? 0.10 : 0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        isSelected ? Theme.Colors.electric : Color.white.opacity(0.08),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Pro Feature Row (legacy — kept for external use)

struct ProFeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(Theme.Colors.primary.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.Fonts.bodyBold())
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text(subtitle)
                    .font(Theme.Fonts.caption())
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(.vertical, Theme.Spacing.xs)
    }
}

// MARK: - Pro Plan Card (legacy — kept for external use)

struct ProPlanCard: View {
    let title: String
    let price: String
    let period: String
    let perMonthPrice: String?
    let badge: String?
    let badgeColor: Color
    let isSelected: Bool
    let isRecommended: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            onTap()
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: Theme.Spacing.sm) {
                        Text(title)
                            .font(Theme.Fonts.subheading())
                            .foregroundStyle(Theme.Colors.textPrimary)

                        if let badge = badge {
                            Text(badge)
                                .font(Theme.Fonts.micro())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(badgeColor)
                                .clipShape(Capsule())
                        }
                    }

                    HStack(spacing: 4) {
                        Text(price)
                            .font(Theme.Fonts.bodyBold())
                            .foregroundStyle(Theme.Colors.textPrimary)
                        Text(period)
                            .font(Theme.Fonts.caption())
                            .foregroundStyle(Theme.Colors.textTertiary)
                    }

                    if let perMonth = perMonthPrice {
                        Text(perMonth)
                            .font(Theme.Fonts.caption())
                            .foregroundStyle(Theme.Colors.primary)
                    }
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(isSelected ? Theme.Colors.primary : Color.white.opacity(0.2), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    if isSelected {
                        Circle()
                            .fill(Theme.Colors.primary)
                            .frame(width: 14, height: 14)
                    }
                }
            }
            .padding(Theme.Spacing.md)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                    .stroke(isSelected ? Theme.Colors.primary : Color.white.opacity(0.1), lineWidth: isSelected ? 2 : 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Pooply Pro Card (Upsell card for Insights & Profile)

struct PooplyProCard: View {
    let onUpgrade: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // PRO badge — electric yellow w/ crown
            HStack(spacing: 6) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 12, weight: .bold))
                Text("PRO")
                    .font(Theme.Fonts.label(12))
                    .tracking(1.8)
            }
            .foregroundStyle(Theme.Colors.neutral900)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(Theme.Colors.electric))

            Text("Unlock Your\nGut Intelligence")
                .font(Theme.Fonts.title(24))
                .foregroundStyle(.white)
                .lineSpacing(2)

            Text("AI-powered insights, pattern detection, and personalized recommendations.")
                .font(Theme.Fonts.body(14))
                .foregroundStyle(.white.opacity(0.65))
                .lineSpacing(2)

            VStack(alignment: .leading, spacing: 10) {
                ProCardFeatureRow(icon: "camera.viewfinder", text: "Unlimited AI Photo Analysis")
                ProCardFeatureRow(icon: "brain.head.profile", text: "Smart Gut Health Insights")
                ProCardFeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Advanced Trend Tracking")
            }
            .padding(.top, Theme.Spacing.xs)

            // CTA — 3D elevated electric yellow with crown
            Button(action: {
                Theme.Haptics.medium()
                onUpgrade()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 14, weight: .bold))
                    Text("Upgrade to Pro")
                        .font(Theme.Fonts.bodyBold())
                }
                .foregroundStyle(Theme.Colors.neutral900)
            }
            .elevatedButtonStyle(color: Theme.Colors.electric, height: 52)
            .padding(.top, Theme.Spacing.sm)
        }
        .padding(Theme.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.xl, style: .continuous)
                .fill(Theme.Colors.neutral900)
        )
    }
}

// MARK: - Pro Card Feature Row

struct ProCardFeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Theme.Colors.electric)
                .frame(width: 20)
            Text(text)
                .font(Theme.Fonts.body(14))
                .foregroundStyle(.white.opacity(0.85))
        }
    }
}

// MARK: - Pro Pill (legacy, kept for compatibility)

struct ProPill: View {
    let icon: String
    let text: String
    var body: some View { EmptyView() }
}

// MARK: - Preview

#Preview {
    PaywallView()
        .environmentObject(SubscriptionService.shared)
}
