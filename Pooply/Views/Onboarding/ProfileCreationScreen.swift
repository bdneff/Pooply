//
//  ProfileCreationScreen.swift
//  Pooply
//
//  Shared components for onboarding screens
//

import SwiftUI

// MARK: - Profile Input Card

struct ProfileInputCard<Content: View>: View {
    let title: String
    let icon: String
    let content: Content

    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.Colors.textOnGlass.opacity(0.55))

                Text(title)
                    .font(Theme.Fonts.subheading(16))
                    .foregroundStyle(Theme.Colors.textOnGlass)
            }

            content
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassSurface(radius: Theme.Radius.medium)
    }
}

// MARK: - Gender Option Button

struct GenderOptionButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    @State private var pressed = false

    var body: some View {
        Button(action: {
            Theme.Haptics.light()
            action()
        }) {
            Text(title)
                .font(Theme.Fonts.bodyBold())
                .foregroundStyle(Theme.Colors.textOnGlass)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .contentShape(Rectangle())
                .glassSurface(radius: Theme.Radius.medium)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                        .fill(Theme.Colors.iconBlue400.opacity(isSelected ? 0.12 : 0))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                        .stroke(
                            Theme.Colors.iconBlue400.opacity(isSelected ? 1.0 : 0),
                            lineWidth: 2.5
                        )
                )
                .scaleEffect(pressed ? 0.97 : 1.0)
                .animation(.easeOut(duration: 0.15), value: pressed)
                .animation(.easeOut(duration: 0.18), value: isSelected)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            pressed = pressing
        }, perform: {})
    }
}

// MARK: - Answer Option Button

struct AnswerOptionButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    @State private var pressed = false

    var body: some View {
        Button(action: {
            Theme.Haptics.light()
            action()
        }) {
            HStack {
                Text(title)
                    .font(Theme.Fonts.body())
                    .foregroundStyle(Theme.Colors.textOnGlass)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                // Checkmark circle
                ZStack {
                    Circle()
                        .stroke(
                            isSelected ? Theme.Colors.iconBlue400 : Theme.Colors.neutralLight,
                            lineWidth: 2
                        )
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(Theme.Colors.iconBlue400)
                            .frame(width: 14, height: 14)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
            .contentShape(Rectangle())
            .glassSurface(radius: Theme.Radius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                    .fill(Theme.Colors.iconBlue400.opacity(isSelected ? 0.12 : 0))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                    .stroke(
                        Theme.Colors.iconBlue400.opacity(isSelected ? 1.0 : 0),
                        lineWidth: 2.5
                    )
            )
            .scaleEffect(pressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.15), value: pressed)
            .animation(.easeOut(duration: 0.18), value: isSelected)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            pressed = pressing
        }, perform: {})
    }
}

// MARK: - Completion Stat

struct CompletionStat: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(Theme.Fonts.heading())
                .foregroundStyle(Theme.Colors.textPrimary)

            Text(label)
                .font(Theme.Fonts.caption())
                .foregroundStyle(Theme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.md)
        .background(Theme.Colors.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}
