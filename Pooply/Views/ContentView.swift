//
//  ContentView.swift
//  Pooply
//
//  v4 — Mesh bg, glass pill nav bottom-left, glass + FAB bottom-right.
//  Home / Insights swap inline. Profile opens from mascot tap.
//

import SwiftUI

// Legacy Tab enum kept so non-rewritten code paths still compile
enum Tab: CaseIterable {
    case scan
    case gut
    case profile

    var iconFilled: String {
        switch self {
        case .scan: return "camera.fill"
        case .gut: return "chart.bar.fill"
        case .profile: return "person.fill"
        }
    }

    var iconOutline: String {
        switch self {
        case .scan: return "camera"
        case .gut: return "chart.bar"
        case .profile: return "person"
        }
    }

    var label: String {
        switch self {
        case .scan: return "Scan"
        case .gut: return "Data"
        case .profile: return "Profile"
        }
    }

    var icon: String { iconFilled }
}

struct ContentView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var subscriptionService: SubscriptionService

    @State private var selectedPage: AppPage = .home
    @State private var showCameraView: Bool = false
    @State private var showManualEntry: Bool = false
    @State private var showProfile: Bool = false
    @State private var showLogOptions: Bool = false
    @State private var showRatingCard: Bool = false
    @State private var homeTimeframe: String = "WEEK"

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedPage {
                case .home:
                    MeshBackground()
                case .insights:
                    InsightsBackground()
                }
            }
            .animation(.easeInOut(duration: 0.35), value: selectedPage)

            Group {
                switch selectedPage {
                case .home:
                    HomeView(
                        selectedTimeframe: $homeTimeframe,
                        showProfile: $showProfile,
                        showLogOptions: $showLogOptions
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))

                case .insights:
                    InsightsView(showProfile: $showProfile)
                        .environmentObject(userViewModel)
                        .environmentObject(subscriptionService)
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.82), value: selectedPage)

            HStack(alignment: .center) {
                GlassNavPill(selected: $selectedPage)
                Spacer()
                GlassFAB {
                    showLogOptions = true
                }
            }
            .padding(.horizontal, Theme.Spacing.screenHorizontal)
            .padding(.bottom, 24)

            if showRatingCard {
                RatingCard(isPresented: $showRatingCard)
                    .zIndex(2)
            }
        }
        .sheet(isPresented: $showLogOptions) {
            LogOptionsSheet(
                onCamera: {
                    showLogOptions = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        showCameraView = true
                    }
                },
                onManual: {
                    showLogOptions = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        showManualEntry = true
                    }
                }
            )
            .presentationDetents([.fraction(0.42)])
            .presentationDragIndicator(.visible)
            .presentationBackground(.clear)
        }
        .sheet(isPresented: $showProfile) {
            ProfileModal(isPresented: $showProfile)
                .environmentObject(userViewModel)
                .environmentObject(subscriptionService)
                .presentationBackground(.clear)
                .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $showCameraView) {
            CameraView(isPresented: $showCameraView, showManualEntry: $showManualEntry)
                .environmentObject(userViewModel)
                .environmentObject(subscriptionService)
        }
        .sheet(isPresented: $showManualEntry) {
            ManualEntryView(isPresented: $showManualEntry)
                .environmentObject(userViewModel)
                .presentationBackground(.clear)
                .presentationDragIndicator(.visible)
        }
        .onChange(of: userViewModel.logHistory.count) { _, newCount in
            if RatingCard.shouldShowRating(logCount: newCount) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    showRatingCard = true
                }
            }
        }
    }
}

// MARK: - KPI Item (legacy)

struct KPIItem: View {
    let value: String
    let unit: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(Theme.Fonts.metric(28))
                    .foregroundStyle(Theme.Colors.textOnGlass)
                    .contentTransition(.numericText())

                if !unit.isEmpty {
                    Text(unit)
                        .font(Theme.Fonts.caption())
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
            }

            Text(label)
                .font(Theme.Fonts.caption())
                .foregroundStyle(Theme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Mini Gauge KPI (legacy)

struct MiniGaugeKPI: View {
    let value: Int
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .trim(from: 0, to: 0.75)
                    .stroke(color.opacity(0.15), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(135))

                Circle()
                    .trim(from: 0, to: 0.75 * (CGFloat(value) / 100.0))
                    .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(135))

                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(color)
            }
            .frame(width: 44, height: 44)

            Text("\(value)%")
                .font(Theme.Fonts.bodyBold())
                .foregroundStyle(Theme.Colors.textOnGlass)
                .contentTransition(.numericText())

            Text(label)
                .font(Theme.Fonts.micro())
                .foregroundStyle(Theme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Log Options Sheet (the FAB target)

struct LogOptionsSheet: View {
    let onCamera: () -> Void
    let onManual: () -> Void

    var body: some View {
        ZStack {
            FrostedSheetBackground()

            VStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text("How are we logging?")
                        .font(Theme.Fonts.title(24))
                        .foregroundStyle(Theme.Colors.textOnGlass)
                    Text("Pick your method")
                        .font(Theme.Fonts.body(14))
                        .foregroundStyle(Theme.Colors.textOnGlass.opacity(0.6))
                }
                .padding(.top, 24)
                .padding(.bottom, 8)

                HStack(spacing: 14) {
                    LogOptionTile(
                        title: "Scan",
                        subtitle: "Use the camera",
                        icon: "camera.fill",
                        iconBackground: Theme.Colors.popBlue,
                        action: onCamera
                    )
                    LogOptionTile(
                        title: "Manual",
                        subtitle: "Type it in",
                        icon: "pencil.line",
                        iconBackground: Theme.Colors.neutral900,
                        action: onManual
                    )
                }
                .padding(.horizontal, Theme.Spacing.screenHorizontal)

                Spacer(minLength: 0)
            }
        }
    }
}

struct LogOptionTile: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconBackground: Color
    let action: () -> Void

    @State private var pressed: Bool = false

    var body: some View {
        Button {
            Theme.Haptics.medium()
            action()
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                ZStack {
                    Circle().fill(iconBackground)
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                }

                Spacer()

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Theme.Fonts.heading(20))
                        .foregroundStyle(Theme.Colors.textOnGlass)
                    Text(subtitle)
                        .font(Theme.Fonts.caption(13))
                        .foregroundStyle(Theme.Colors.textOnGlass.opacity(0.6))
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 140, alignment: .topLeading)
            .contentShape(Rectangle())
            .glassSurface(radius: 22)
            .scaleEffect(pressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { isPressing in
            withAnimation(Theme.Animation.press) { pressed = isPressing }
        }, perform: {})
    }
}

#Preview {
    ContentView()
        .environmentObject(
            UserViewModel(
                user: User(name: "Brandon", age: 25, weight: 160, gender: "male"),
                withDummyData: true
            )
        )
        .environmentObject(SubscriptionService.shared)
}
