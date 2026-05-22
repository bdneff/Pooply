//
//  FloatingTabBar.swift
//  Pooply
//
//  Floating capsule tab bar with iOS 26 Liquid Glass effect + FAB
//

import SwiftUI

struct FloatingTabBar: View {
    @Binding var selectedTab: Tab
    let onAddTap: () -> Void

    var body: some View {
        HStack(alignment: .center) {
            // Floating capsule tab bar with liquid glass
            HStack(spacing: 28) {
                FloatingTabItem(
                    icon: "house.fill",
                    label: "Home",
                    isSelected: selectedTab == .scan,
                    action: { selectedTab = .scan }
                )

                FloatingTabItem(
                    icon: "chart.bar.fill",
                    label: "Insights",
                    isSelected: selectedTab == .gut,
                    action: { selectedTab = .gut }
                )
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .modifier(LiquidGlassModifier())
            .clipShape(Capsule())

            Spacer()

            // FAB - Add Log Button
            AddLogFAB(action: onAddTap)
        }
        .padding(.horizontal, Theme.Spacing.screenHorizontal)
        .padding(.bottom, 8)
    }
}

// MARK: - Liquid Glass Modifier (iOS 26+ with fallback)

struct LiquidGlassModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(.regular.interactive())
        } else {
            // Fallback for older iOS versions
            content
                .background {
                    ZStack {
                        RoundedRectangle(cornerRadius: 100)
                            .fill(.ultraThinMaterial)

                        RoundedRectangle(cornerRadius: 100)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.7),
                                        Color.white.opacity(0.4),
                                        Color.white.opacity(0.5)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        RoundedRectangle(cornerRadius: 100)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.5),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .center
                                )
                            )

                        RoundedRectangle(cornerRadius: 100)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.6),
                                        Color.white.opacity(0.2),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                }
                .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 10)
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
        }
    }
}

// MARK: - Floating Tab Item

private struct FloatingTabItem: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            action()
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))

                Text(label)
                    .font(Theme.Fonts.micro())
            }
            .foregroundStyle(isSelected ? Theme.Colors.tabBarSelected : Theme.Colors.neutralDark)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Add Log FAB

struct AddLogFAB: View {
    let action: () -> Void
    var size: CGFloat = 56
    var iconSize: CGFloat = 24

    @State private var isPressed = false
    @State private var ringScale: CGFloat = 1
    @State private var ringOpacity: Double = 0

    var body: some View {
        Button(action: {
            // Trigger ring animation
            triggerRingAnimation()

            let impactMed = UIImpactFeedbackGenerator(style: .medium)
            impactMed.impactOccurred()

            // Delay action slightly for visual feedback
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                action()
            }
        }) {
            ZStack {
                // Expanding ring animation
                Circle()
                    .stroke(Theme.Colors.primary, lineWidth: 3)
                    .frame(width: size, height: size)
                    .scaleEffect(ringScale)
                    .opacity(ringOpacity)

                // Main button with glass effect as background
                if #available(iOS 26.0, *) {
                    Circle()
                        .fill(Theme.Colors.primary)
                        .frame(width: size, height: size)
                        .scaleEffect(isPressed ? 0.8 : 1.0)
                        .glassEffect(.regular)
                } else {
                    Circle()
                        .fill(Theme.Colors.primary)
                        .frame(width: size, height: size)
                        .scaleEffect(isPressed ? 0.8 : 1.0)
                }

                // Plus icon
                Image(systemName: "plus")
                    .font(.system(size: iconSize, weight: .bold))
                    .foregroundStyle(Theme.Colors.textOnPrimary)
                    .scaleEffect(isPressed ? 0.8 : 1.0)
            }
        }
        .buttonStyle(FABButtonStyle(isPressed: $isPressed))
        .shadow(color: Theme.Colors.primary.opacity(0.4), radius: 12, x: 0, y: 6)
        .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 10)
    }

    private func triggerRingAnimation() {
        // Reset
        ringScale = 1
        ringOpacity = 0.8

        // Animate outward and fade
        withAnimation(.easeOut(duration: 0.4)) {
            ringScale = 1.8
            ringOpacity = 0
        }
    }
}

// Custom button style to track press state
struct FABButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, newValue in
                withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                    isPressed = newValue
                }
            }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        // Background with content to show glass effect
        LinearGradient(
            colors: [
                Theme.Colors.tealTint,
                Theme.Colors.background,
                Theme.Colors.blueTint
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        VStack {
            Spacer()
            FloatingTabBar(
                selectedTab: .constant(.scan),
                onAddTap: {}
            )
        }
    }
}
