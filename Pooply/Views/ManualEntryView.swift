//
//  ManualEntryView.swift
//  Pooply
//
//  Manual Log Entry
//

import SwiftUI

struct ManualEntryView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var userViewModel: UserViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedType: Log.PoopType = .smoothSausage
    @State private var selectedColor: Log.PoopColor = .mediumBrown
    @State private var selectedSize: Log.PoopSize = .medium
    @State private var containsBlood = false
    @State private var useCurrentTime = true
    @State private var selectedDate = Date()

    private let allTypes: [Log.PoopType] = Log.PoopType.allCases

    private let allColors: [Log.PoopColor] = [
        .lightBrown, .mediumBrown, .darkBrown, .green, .yellow, .black, .red
    ]

    private let allSizes: [Log.PoopSize] = [
        .small, .medium, .large
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {

                    // MARK: - When
                    SectionCard {
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            EntrySectionLabel(text: "When", icon: "clock.fill")

                            HStack(spacing: Theme.Spacing.sm) {
                                EntryPillButton(title: "Now", icon: "clock.fill", isSelected: useCurrentTime) {
                                    withAnimation(Theme.Animation.snap) { useCurrentTime = true }
                                }
                                EntryPillButton(title: "Custom", icon: "calendar", isSelected: !useCurrentTime) {
                                    withAnimation(Theme.Animation.snap) { useCurrentTime = false }
                                }
                            }

                            if !useCurrentTime {
                                DatePicker(
                                    "Select Date",
                                    selection: $selectedDate,
                                    displayedComponents: [.date, .hourAndMinute]
                                )
                                .datePickerStyle(.compact)
                                .tint(Theme.Colors.primary)
                                .labelsHidden()
                                .padding(Theme.Spacing.sm)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .background(Theme.Colors.backgroundSecondary)
                                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small, style: .continuous))
                                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                            }
                        }
                        .animation(Theme.Animation.spring, value: useCurrentTime)
                    }

                    // MARK: - Type
                    SectionCard {
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            EntrySectionLabel(text: "Type", icon: "list.bullet")

                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 10),
                                GridItem(.flexible(), spacing: 10),
                                GridItem(.flexible(), spacing: 10)
                            ], spacing: 10) {
                                ForEach(allTypes, id: \.self) { type in
                                    EntryTypeGridItem(
                                        type: type,
                                        isSelected: selectedType == type,
                                        action: {
                                            withAnimation(Theme.Animation.snap) {
                                                selectedType = type
                                            }
                                        }
                                    )
                                }
                            }
                        }
                    }

                    // MARK: - Color
                    SectionCard {
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            EntrySectionLabel(text: "Color", icon: "paintpalette.fill")

                            HStack(spacing: 0) {
                                ForEach(allColors, id: \.self) { color in
                                    EntryColorSwatch(
                                        poopColor: color,
                                        isSelected: selectedColor == color,
                                        action: {
                                            withAnimation(Theme.Animation.snap) {
                                                selectedColor = color
                                            }
                                        }
                                    )
                                    .frame(maxWidth: .infinity)
                                }
                            }

                            Text(colorLabel(for: selectedColor))
                                .font(Theme.Fonts.caption())
                                .foregroundStyle(Theme.Colors.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .contentTransition(.numericText())
                        }
                    }

                    // MARK: - Size
                    SectionCard {
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            EntrySectionLabel(text: "Size", icon: "circle.lefthalf.filled")

                            HStack(spacing: Theme.Spacing.sm) {
                                ForEach(allSizes, id: \.self) { size in
                                    EntrySizeOptionButton(
                                        size: size,
                                        isSelected: selectedSize == size,
                                        action: {
                                            withAnimation(Theme.Animation.snap) {
                                                selectedSize = size
                                            }
                                        }
                                    )
                                }
                            }
                        }
                    }

                    // MARK: - Blood
                    SectionCard {
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "drop.fill")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundStyle(Theme.Colors.blood)
                                        Text("Blood Present")
                                            .font(Theme.Fonts.bodyBold())
                                            .foregroundStyle(Theme.Colors.textPrimary)
                                    }

                                    Text("Toggle if you noticed any blood")
                                        .font(Theme.Fonts.caption())
                                        .foregroundStyle(Theme.Colors.textTertiary)
                                }

                                Spacer()

                                Toggle("", isOn: $containsBlood)
                                    .labelsHidden()
                                    .toggleStyle(SwitchToggleStyle(tint: Theme.Colors.blood))
                                    .onChange(of: containsBlood) { _, newValue in
                                        if newValue {
                                            let impact = UIImpactFeedbackGenerator(style: .medium)
                                            impact.impactOccurred()
                                        }
                                    }
                            }

                            if containsBlood {
                                HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 14))
                                        .foregroundStyle(Theme.Colors.blood)

                                    Text("Blood in stool can indicate various conditions. If frequent, please consult a healthcare professional.")
                                        .font(Theme.Fonts.caption())
                                        .foregroundStyle(Theme.Colors.textSecondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(Theme.Spacing.md)
                                .background(Theme.Colors.blood.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small, style: .continuous))
                                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                            }
                        }
                        .animation(Theme.Animation.spring, value: containsBlood)
                    }

                    // Bottom spacing for safe area
                    Spacer().frame(height: Theme.Spacing.xl)
                }
                .padding(.horizontal, Theme.Spacing.screenHorizontal)
                .padding(.top, Theme.Spacing.sm)
            }
            .background(Theme.Colors.background)
            .navigationTitle("Log Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.Colors.background, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Text("Cancel")
                            .font(Theme.Fonts.body())
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: saveLog) {
                        Text("Save")
                            .font(Theme.Fonts.bodyBold())
                            .foregroundStyle(Theme.Colors.textOnPrimary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(Theme.Colors.primary)
                            .clipShape(Capsule())
                    }
                }
            }
            .tint(Theme.Colors.primary)
        }
    }

    // MARK: - Helpers

    private func colorLabel(for poopColor: Log.PoopColor) -> String {
        switch poopColor {
        case .lightBrown: return "Light Brown"
        case .mediumBrown: return "Medium Brown (Normal)"
        case .darkBrown: return "Dark Brown"
        case .green: return "Green"
        case .yellow: return "Yellow"
        case .black: return "Black"
        case .red: return "Red"
        }
    }

    private func saveLog() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        let timestamp = useCurrentTime ? Date() : selectedDate

        let newLog = userViewModel.createManualLog(
            type: selectedType,
            color: selectedColor,
            size: selectedSize,
            containsBlood: containsBlood,
            timestamp: timestamp
        )

        userViewModel.addLog(newLog)
        Task { try? await FirebaseService.shared.saveLog(newLog) }

        dismiss()
    }
}

// MARK: - Section Card Container

private struct SectionCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(Theme.Spacing.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.large, style: .continuous))
            .cardShadow()
    }
}

// MARK: - Section Label with Icon

private struct EntrySectionLabel: View {
    let text: String
    let icon: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.Colors.primary)
            Text(text)
                .font(Theme.Fonts.subheading())
                .foregroundStyle(Theme.Colors.textPrimary)
        }
        .padding(.bottom, 4)
    }
}

// MARK: - Pill Button

private struct EntryPillButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            action()
        }) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(title)
                    .font(Theme.Fonts.bodyBold())
            }
            .foregroundStyle(isSelected ? Theme.Colors.textOnPrimary : Theme.Colors.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isSelected ? Theme.Colors.primary : Theme.Colors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Type Grid Item

private struct EntryTypeGridItem: View {
    let type: Log.PoopType
    let isSelected: Bool
    let action: () -> Void

    private var typeLabel: String {
        switch type {
        case .separateHardLumps: return "Hard Lumps"
        case .lumpySausage: return "Lumpy"
        case .crackedSausage: return "Cracked"
        case .smoothSausage: return "Smooth"
        case .softBlobs: return "Soft Blobs"
        case .fluffyPieces: return "Fluffy"
        case .watery: return "Watery"
        }
    }

    private var typeNumber: Int {
        switch type {
        case .separateHardLumps: return 1
        case .lumpySausage: return 2
        case .crackedSausage: return 3
        case .smoothSausage: return 4
        case .softBlobs: return 5
        case .fluffyPieces: return 6
        case .watery: return 7
        }
    }

    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            action()
        }) {
            VStack(spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    Image(type.rawValue)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)

                    Text("\(typeNumber)")
                        .font(Theme.Fonts.micro())
                        .foregroundStyle(Theme.Colors.textTertiary)
                        .frame(width: 18, height: 18)
                        .background(Theme.Colors.backgroundSecondary)
                        .clipShape(Circle())
                        .offset(x: 4, y: -4)
                }

                Text(typeLabel)
                    .font(Theme.Fonts.caption())
                    .foregroundStyle(isSelected ? Theme.Colors.primary : Theme.Colors.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(isSelected ? Theme.Colors.primary.opacity(0.12) : Theme.Colors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                    .stroke(isSelected ? Theme.Colors.primary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Color Swatch

private struct EntryColorSwatch: View {
    let poopColor: Log.PoopColor
    let isSelected: Bool
    let action: () -> Void

    private var swatchColor: Color {
        switch poopColor {
        case .lightBrown: return Color(hex: "#D2B48C")
        case .mediumBrown: return Color(hex: "#8B4513")
        case .darkBrown: return Color(hex: "#654321")
        case .green: return Color(hex: "#228B22")
        case .yellow: return Color(hex: "#FFD700")
        case .black: return Color(hex: "#2F2F2F")
        case .red: return Color(hex: "#B22222")
        }
    }

    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            action()
        }) {
            Circle()
                .fill(swatchColor)
                .frame(width: 36, height: 36)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: isSelected ? 2.5 : 0)
                )
                .overlay(
                    Circle()
                        .stroke(isSelected ? Theme.Colors.primary : Theme.Colors.neutralLight.opacity(0.5), lineWidth: isSelected ? 2.5 : 1)
                        .padding(isSelected ? -1 : 0)
                )
                .scaleEffect(isSelected ? 1.08 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Size Option Button

private struct EntrySizeOptionButton: View {
    let size: Log.PoopSize
    let isSelected: Bool
    let action: () -> Void

    private var iconSize: CGFloat {
        switch size {
        case .small: return 12
        case .medium: return 18
        case .large: return 24
        }
    }

    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            action()
        }) {
            VStack(spacing: 8) {
                Circle()
                    .fill(isSelected ? Theme.Colors.primary : Theme.Colors.neutralLight)
                    .frame(width: iconSize, height: iconSize)

                Text(size.rawValue.capitalized)
                    .font(Theme.Fonts.bodyBold())
            }
            .foregroundStyle(isSelected ? Theme.Colors.primary : Theme.Colors.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? Theme.Colors.primary.opacity(0.12) : Theme.Colors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                    .stroke(isSelected ? Theme.Colors.primary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    ManualEntryView(isPresented: .constant(true))
        .environmentObject(
            UserViewModel(
                user: User(name: "Jessica", age: 25, weight: 160, gender: "female"),
                withDummyData: true
            )
        )
}
