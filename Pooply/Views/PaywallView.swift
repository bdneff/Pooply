//
//  PaywallView.swift
//  Pooply
//
//  Pooply Pro upgrade modal — shown from camera, insights, and profile
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

    enum PlanType {
        case monthly, annual
    }

    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Close button
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Theme.Colors.textTertiary)
                            .frame(width: 32, height: 32)
                            .background(Theme.Colors.backgroundSecondary)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, Theme.Spacing.screenHorizontal)
                .padding(.top, Theme.Spacing.sm)

                Spacer()

                // Header
                headerSection

                // Features list
                featuresSection
                    .padding(.top, Theme.Spacing.md)

                Spacer()

                // Plan cards
                planCardsSection
                    .padding(.top, Theme.Spacing.sm)

                // Error
                if let error = errorMessage {
                    Text(error)
                        .font(Theme.Fonts.caption())
                        .foregroundStyle(Theme.Colors.blood)
                        .multilineTextAlignment(.center)
                        .padding(.top, Theme.Spacing.xs)
                }

                // Purchase button
                purchaseButton
                    .padding(.top, Theme.Spacing.sm)

                // Footer
                footerSection
                    .padding(.top, Theme.Spacing.sm)
                    .padding(.bottom, Theme.Spacing.md)
            }
        }
        .onAppear {
            Analytics.logEvent("paywall_shown", parameters: [
                "source": "upgrade"
            ])
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Mascot
            MascotCircle(size: 80)

            // Pro badge
            HStack(spacing: 6) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 14))
                Text("PRO")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .kerning(1.5)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                LinearGradient(
                    colors: [Theme.Colors.primary, Theme.Colors.primary.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())

            Text("Upgrade to\nPooply Pro")
                .font(Theme.Fonts.hero(32))
                .foregroundStyle(Theme.Colors.textPrimary)
                .multilineTextAlignment(.center)

            Text("Unlock the full power of AI-driven\ngut health tracking")
                .font(Theme.Fonts.body())
                .foregroundStyle(Theme.Colors.textTertiary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Features

    private var featuresSection: some View {
        VStack(spacing: 0) {
            ProFeatureRow(
                icon: "camera.viewfinder",
                title: "Unlimited AI Analysis",
                subtitle: "Snap a photo and get instant Bristol type, color, and health scoring"
            )
            ProFeatureRow(
                icon: "brain.head.profile",
                title: "Smart Insights",
                subtitle: "AI-powered trends, patterns, and personalized recommendations"
            )
            ProFeatureRow(
                icon: "chart.line.uptrend.xyaxis",
                title: "Advanced Analytics",
                subtitle: "Detailed gut health metrics your doctor will love"
            )
            ProFeatureRow(
                icon: "bell.badge.fill",
                title: "Early Access",
                subtitle: "Be first to try new features as we build them"
            )
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.xs)
        .background(Theme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.large, style: .continuous))
        .cardShadow()
        .padding(.horizontal, Theme.Spacing.screenHorizontal)
    }

    // MARK: - Plan Cards

    private var planCardsSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            // Annual — highlighted
            ProPlanCard(
                title: "Annual",
                price: subscriptionService.annualPriceString,
                period: "/year",
                perMonthPrice: "$2.50/mo",
                badge: "SAVE 65%",
                badgeColor: Color.orange,
                isSelected: selectedPlan == .annual,
                isRecommended: true,
                onTap: { withAnimation(Theme.Animation.snap) { selectedPlan = .annual } }
            )

            // Monthly
            ProPlanCard(
                title: "Monthly",
                price: subscriptionService.monthlyPriceString,
                period: "/month",
                perMonthPrice: nil,
                badge: nil,
                badgeColor: .clear,
                isSelected: selectedPlan == .monthly,
                isRecommended: false,
                onTap: { withAnimation(Theme.Animation.snap) { selectedPlan = .monthly } }
            )
        }
        .padding(.horizontal, Theme.Spacing.screenHorizontal)
    }

    // MARK: - Purchase Button

    private var purchaseButton: some View {
        Button(action: purchaseSelectedPlan) {
            HStack(spacing: Theme.Spacing.sm) {
                if isPurchasing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 14))
                    Text("Upgrade to Pro")
                        .font(Theme.Fonts.bodyBold())
                }
            }
        }
        .elevatedButtonStyle()
        .disabled(isPurchasing)
        .padding(.horizontal, Theme.Spacing.screenHorizontal)
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Button(action: restorePurchases) {
                Text("Restore Purchases")
                    .font(Theme.Fonts.micro())
                    .foregroundStyle(Theme.Colors.textTertiary)
            }

            HStack(spacing: Theme.Spacing.lg) {
                Link("Terms of Service", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                    .font(Theme.Fonts.micro())
                    .foregroundStyle(Theme.Colors.textTertiary)

                Link("Privacy Policy", destination: URL(string: "https://grossyb.github.io/pooply_privacy/")!)
                    .font(Theme.Fonts.micro())
                    .foregroundStyle(Theme.Colors.textTertiary)
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

// MARK: - Pro Feature Row

struct ProFeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.Colors.primary)
                .frame(width: 36, height: 36)
                .background(Theme.Colors.primary.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.Fonts.bodyBold())
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text(subtitle)
                    .font(Theme.Fonts.caption())
                    .foregroundStyle(Theme.Colors.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(.vertical, Theme.Spacing.xs)
    }
}

// MARK: - Pro Plan Card

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

                        if isRecommended {
                            Text("BEST VALUE")
                                .font(Theme.Fonts.micro())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Theme.Colors.primary)
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

                // Radio button
                ZStack {
                    Circle()
                        .stroke(isSelected ? Theme.Colors.primary : Theme.Colors.neutralLight, lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(Theme.Colors.primary)
                            .frame(width: 14, height: 14)
                    }
                }
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                    .stroke(isSelected ? Theme.Colors.primary : Theme.Colors.neutralLight.opacity(0.5), lineWidth: isSelected ? 2 : 1)
            )
            .cardShadow()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Pooply Pro Card (Upsell card for Insights & Profile)

struct PooplyProCard: View {
    let onUpgrade: () -> Void

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Crown icon
            Image(systemName: "crown.fill")
                .font(.system(size: 32))
                .foregroundStyle(Theme.Colors.primary)

            Text("Unlock Smart Insights")
                .font(Theme.Fonts.heading())
                .foregroundStyle(Theme.Colors.textPrimary)

            Text("Upgrade to Pooply Pro for AI-powered\ntrend analysis, pattern detection, and\npersonalized gut health recommendations.")
                .font(Theme.Fonts.caption())
                .foregroundStyle(Theme.Colors.textTertiary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)

            // Feature pills
            HStack(spacing: Theme.Spacing.sm) {
                ProPill(icon: "camera.viewfinder", text: "AI Analysis")
                ProPill(icon: "brain.head.profile", text: "Insights")
                ProPill(icon: "chart.bar.fill", text: "Trends")
            }

            Button(action: {
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
                onUpgrade()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 12))
                    Text("Upgrade to Pro")
                        .font(Theme.Fonts.bodyBold())
                }
            }
            .elevatedButtonStyle(height: 48)
        }
        .padding(Theme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.large, style: .continuous)
                .fill(Theme.Colors.cardBackground)
        )
        .cardShadow()
    }
}

// MARK: - Pro Pill

struct ProPill: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(text)
                .font(Theme.Fonts.micro())
        }
        .foregroundStyle(Theme.Colors.primary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Theme.Colors.primary.opacity(0.1))
        .clipShape(Capsule())
    }
}

// MARK: - Preview

#Preview {
    PaywallView()
        .environmentObject(SubscriptionService.shared)
}
