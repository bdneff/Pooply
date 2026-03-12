//
//  ContentView.swift
//  Pooply
//
//  Created by Brandon Grossnickle on 9/19/25.
//

import SwiftUI

enum Tab: CaseIterable {
    case home
    case insights

    var icon: String {
        switch self {
            case .home: return "house.fill"
            case .insights: return "chart.bar.fill"
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var subscriptionService: SubscriptionService

    @State private var selectedTab: Tab = .home
    @State private var showProfileModal: Bool = false
    @State private var showCameraView: Bool = false
    @State private var showManualEntry: Bool = false
    @State private var showRatingCard: Bool = false
    @State private var showPaywall: Bool = false
    @State private var showLogOptions: Bool = false

    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                switch selectedTab {
                case .home:
                    HomeView(
                        showCameraView: $showCameraView,
                        showManualEntry: $showManualEntry,
                        showProfileModal: $showProfileModal
                    )
                case .insights:
                    InsightsView()
                        .environmentObject(userViewModel)
                }
            }
            .animation(Theme.Animation.spring, value: selectedTab)

            // Floating Tab Bar — FAB shows log options
            VStack {
                Spacer()
                FloatingTabBar(
                    selectedTab: $selectedTab,
                    onAddTap: {
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                            showLogOptions = true
                        }
                    }
                )
            }

            // Log Options Overlay
            if showLogOptions {
                logOptionsOverlay
            }

            // Rating Card Overlay
            if showRatingCard {
                RatingCard(isPresented: $showRatingCard)
            }
        }
        .fullScreenCover(isPresented: $showCameraView) {
            CameraView(isPresented: $showCameraView, showManualEntry: $showManualEntry)
                .environmentObject(userViewModel)
                .environmentObject(subscriptionService)
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView()
                .environmentObject(subscriptionService)
        }
        .sheet(isPresented: $showManualEntry) {
            ManualEntryView(isPresented: $showManualEntry)
                .environmentObject(userViewModel)
        }
        .sheet(isPresented: $showProfileModal) {
            ProfileModal(isPresented: $showProfileModal)
                .environmentObject(userViewModel)
                .environmentObject(subscriptionService)
        }
        .onChange(of: userViewModel.logHistory.count) { _, newCount in
            if RatingCard.shouldShowRating(logCount: newCount) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    showRatingCard = true
                }
            }
        }
    }

    // MARK: - Log Options Overlay

    private var logOptionsOverlay: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.18, dampingFraction: 0.8)) {
                        showLogOptions = false
                    }
                }

            VStack(spacing: Theme.Spacing.md) {
                // AI Analysis Card
                Button {
                    withAnimation(.spring(response: 0.18, dampingFraction: 0.8)) {
                        showLogOptions = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        if subscriptionService.canUseAIAnalysis {
                            showCameraView = true
                        } else {
                            showPaywall = true
                        }
                    }
                } label: {
                    HStack(spacing: Theme.Spacing.md) {
                        ZStack {
                            Circle()
                                .fill(Theme.Colors.primary.opacity(0.12))
                                .frame(width: 48, height: 48)
                            Image(systemName: "camera.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(Theme.Colors.primary)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("AI Analysis")
                                .font(Theme.Fonts.bodyBold())
                                .foregroundColor(Theme.Colors.textPrimary)
                            Text("Snap a photo for instant health insights")
                                .font(Theme.Fonts.caption())
                                .foregroundColor(Theme.Colors.textTertiary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Theme.Colors.neutralLight)
                    }
                    .padding(Theme.Spacing.md)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous))
                    .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 6)
                }

                // Manual Entry Card
                Button {
                    withAnimation(.spring(response: 0.18, dampingFraction: 0.8)) {
                        showLogOptions = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        showManualEntry = true
                    }
                } label: {
                    HStack(spacing: Theme.Spacing.md) {
                        ZStack {
                            Circle()
                                .fill(Theme.Colors.neutral.opacity(0.12))
                                .frame(width: 48, height: 48)
                            Image(systemName: "pencil.line")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(Theme.Colors.neutral)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Manual Entry")
                                .font(Theme.Fonts.bodyBold())
                                .foregroundColor(Theme.Colors.textPrimary)
                            Text("Log your bowel movement details")
                                .font(Theme.Fonts.caption())
                                .foregroundColor(Theme.Colors.textTertiary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Theme.Colors.neutralLight)
                    }
                    .padding(Theme.Spacing.md)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous))
                    .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 6)
                }
            }
            .padding(.horizontal, Theme.Spacing.screenHorizontal)
            .transition(.scale(scale: 0.85).combined(with: .opacity))
        }
        .transition(.opacity)
    }
}

#Preview {
    ContentView()
        .environmentObject(
            UserViewModel(
                user: User(
                    name: "Preview User",
                    age: 25,
                    weight: 160,
                    gender: "female"
                ),
                withDummyData: true
            )
        )
        .environmentObject(SubscriptionService.shared)
}
