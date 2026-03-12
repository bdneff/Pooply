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
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.Colors.primary)

                Text(title)
                    .font(Theme.Fonts.bodyBold())
                    .foregroundStyle(Theme.Colors.textPrimary)
            }

            content
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous))
        .cardShadow()
    }
}

// MARK: - Gender Option Button

struct GenderOptionButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            action()
        }) {
            Text(title)
                .font(Theme.Fonts.bodyBold())
                .foregroundStyle(isSelected ? Theme.Colors.textOnPrimary : Theme.Colors.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(isSelected ? Theme.Colors.primary : Theme.Colors.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous))
                .shadow(color: Color.black.opacity(isSelected ? 0 : 0.04), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Answer Option Button

struct AnswerOptionButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(Theme.Fonts.body())
                    .foregroundStyle(isSelected ? Theme.Colors.primary : Theme.Colors.textPrimary)

                Spacer()

                // Checkmark circle
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
            .background(isSelected ? Theme.Colors.primary.opacity(0.08) : Theme.Colors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous))
            .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                    .stroke(isSelected ? Theme.Colors.primary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
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
