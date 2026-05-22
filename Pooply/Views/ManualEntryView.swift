//
//  ManualEntryView.swift
//  Pooply
//
//  Manual Log Entry — v4 mesh + glass cards. Sleek vertical grid for Bristol types.
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
    private let allSizes: [Log.PoopSize] = [.small, .medium, .large]

    var body: some View {
        ZStack(alignment: .bottom) {
            FrostedSheetBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {

                // MARK: - Header
                HStack {
                    Button {
                        Theme.Haptics.light()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Theme.Colors.neutral900))
                    }

                    Spacer()

                    Text("New Log")
                        .font(Theme.Fonts.title(20))
                        .foregroundStyle(Theme.Colors.textOnGlass)

                    Spacer()

                    Color.clear.frame(width: 36, height: 36)
                }
                .padding(.horizontal, Theme.Spacing.screenHorizontal)
                .padding(.top, 16)
                .padding(.bottom, 12)

                // MARK: - Content
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 18) {

                        // Type — 2-column grid of all 7 Bristol cards
                        EntryGlassSection(title: "What type?", icon: "list.bullet") {
                            LazyVGrid(
                                columns: [
                                    GridItem(.flexible(), spacing: 10),
                                    GridItem(.flexible(), spacing: 10)
                                ],
                                spacing: 10
                            ) {
                                ForEach(allTypes, id: \.self) { type in
                                    BristolTypeCard(
                                        type: type,
                                        isSelected: selectedType == type,
                                        action: {
                                            withAnimation(Theme.Animation.snap) {
                                                selectedType = type
                                            }
                                            Theme.Haptics.light()
                                        }
                                    )
                                }
                            }
                        }

                        // Color
                        EntryGlassSection(title: "What color?", icon: "paintpalette") {
                            HStack(spacing: 0) {
                                ForEach(allColors, id: \.self) { color in
                                    ColorSwatch(
                                        poopColor: color,
                                        isSelected: selectedColor == color,
                                        action: {
                                            withAnimation(Theme.Animation.snap) {
                                                selectedColor = color
                                            }
                                            Theme.Haptics.light()
                                        }
                                    )
                                    .frame(maxWidth: .infinity)
                                }
                            }
                            Text(colorLabel(for: selectedColor))
                                .font(Theme.Fonts.captionBold(13))
                                .foregroundStyle(Theme.Colors.textOnGlass.opacity(0.65))
                                .frame(maxWidth: .infinity, alignment: .center)
                                .contentTransition(.numericText())
                                .padding(.top, 4)
                        }

                        // Size
                        EntryGlassSection(title: "What size?", icon: "circle.lefthalf.filled") {
                            HStack(spacing: 8) {
                                ForEach(allSizes, id: \.self) { size in
                                    SizeTile(
                                        size: size,
                                        isSelected: selectedSize == size,
                                        action: {
                                            withAnimation(Theme.Animation.snap) {
                                                selectedSize = size
                                            }
                                            Theme.Haptics.light()
                                        }
                                    )
                                }
                            }
                        }

                        // Blood
                        EntryGlassSection(title: "Blood present?", icon: "drop.fill", iconColor: Theme.Colors.coral) {
                            HStack {
                                Text("Toggle if you noticed any blood")
                                    .font(Theme.Fonts.caption(13))
                                    .foregroundStyle(Theme.Colors.textOnGlass.opacity(0.6))
                                Spacer()
                                Toggle("", isOn: $containsBlood)
                                    .labelsHidden()
                                    .toggleStyle(SwitchToggleStyle(tint: Theme.Colors.coral))
                                    .onChange(of: containsBlood) { _, newValue in
                                        if newValue { Theme.Haptics.medium() }
                                    }
                            }

                            if containsBlood {
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Theme.Colors.coral)
                                    Text("If blood persists, consult a healthcare professional.")
                                        .font(Theme.Fonts.caption(12))
                                        .foregroundStyle(Theme.Colors.textOnGlass.opacity(0.7))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(Theme.Colors.coral.opacity(0.10))
                                )
                                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                            }
                        }

                        // When (moved to bottom — set time last)
                        EntryGlassSection(title: "When", icon: "clock") {
                            HStack(spacing: 8) {
                                TimePillButton(title: "Now", icon: "clock.fill", isSelected: useCurrentTime) {
                                    withAnimation(Theme.Animation.snap) { useCurrentTime = true }
                                }
                                TimePillButton(title: "Earlier", icon: "calendar", isSelected: !useCurrentTime) {
                                    withAnimation(Theme.Animation.snap) { useCurrentTime = false }
                                }
                            }
                            if !useCurrentTime {
                                DatePicker("", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                                    .datePickerStyle(.compact)
                                    .tint(Theme.Colors.neutral900)
                                    .labelsHidden()
                                    .environment(\.font, Theme.Fonts.captionBold(14))
                                    .accentColor(Theme.Colors.neutral900)
                                    .padding(.top, 8)
                                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                            }
                        }

                        // Bottom padding so content can scroll past the floating button
                        Spacer().frame(height: 140)
                    }
                    .padding(.horizontal, Theme.Spacing.screenHorizontal)
                }
            }

            // MARK: - Floating Log It button with fade mask above
            VStack(spacing: 0) {
                // Soft fade so content scrolls under and fades out, hinting more to see
                LinearGradient(
                    colors: [Color.white.opacity(0.0), Color.white.opacity(0.55)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 36)
                .allowsHitTesting(false)

                Button(action: saveLog) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16, weight: .bold))
                        Text("Log It")
                            .font(Theme.Fonts.bodyBold())
                    }
                }
                .elevatedButtonStyle(color: Theme.Colors.neutral900, height: 56)
                .padding(.horizontal, Theme.Spacing.screenHorizontal)
                .padding(.bottom, 24)
                .background(Color.white.opacity(0.55))
            }
        }
        .animation(Theme.Animation.spring, value: containsBlood)
        .animation(Theme.Animation.spring, value: useCurrentTime)
    }

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
        Theme.Haptics.success()
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

// MARK: - Entry Glass Section

private struct EntryGlassSection<Content: View>: View {
    let title: String
    let icon: String
    var iconColor: Color = Theme.Colors.textOnGlass.opacity(0.6)
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(iconColor)
                Text(title)
                    .font(Theme.Fonts.subheading(16))
                    .foregroundStyle(Theme.Colors.textOnGlass)
            }
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassSurface(radius: 20)
    }
}

// MARK: - Time Pill Button

private struct TimePillButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            Theme.Haptics.light()
            action()
        }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                Text(title)
                    .font(Theme.Fonts.captionBold(14))
            }
            .foregroundStyle(isSelected ? .white : Theme.Colors.textOnGlass.opacity(0.6))
            .frame(maxWidth: .infinity)
            .frame(height: 42)
            .background(
                Group {
                    if isSelected {
                        Capsule().fill(Theme.Colors.neutral900)
                    } else {
                        Capsule().fill(Color.white.opacity(0.6))
                            .overlay(Capsule().stroke(Color.white.opacity(0.8), lineWidth: 1))
                    }
                }
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Bristol Type Card (2-column grid item)

private struct BristolTypeCard: View {
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

    private var categoryColor: Color {
        switch type {
        case .separateHardLumps, .lumpySausage: return Theme.Colors.hard
        case .crackedSausage, .smoothSausage, .softBlobs: return Theme.Colors.good
        case .fluffyPieces, .watery: return Theme.Colors.loose
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack(alignment: .topTrailing) {
                    Image(type.rawValue)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44, height: 44)

                    Text("\(typeNumber)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Theme.Colors.textOnGlass.opacity(0.6))
                        .frame(width: 16, height: 16)
                        .background(Circle().fill(Color.white))
                        .offset(x: 4, y: -4)
                }

                Text(typeLabel)
                    .font(Theme.Fonts.captionBold(13))
                    .foregroundStyle(Theme.Colors.textOnGlass)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: 0)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? categoryColor.opacity(0.20) : Color.white.opacity(0.55))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? categoryColor : Color.white.opacity(0.9), lineWidth: isSelected ? 2 : 1)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Color Swatch

private struct ColorSwatch: View {
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
        Button(action: action) {
            ZStack {
                if isSelected {
                    Circle()
                        .stroke(swatchColor.opacity(0.6), lineWidth: 2)
                        .frame(width: 38, height: 38)
                }
                Circle()
                    .fill(swatchColor)
                    .frame(width: isSelected ? 28 : 26, height: isSelected ? 28 : 26)
            }
            .frame(height: 44)
            .contentShape(Rectangle())
            .animation(Theme.Animation.snap, value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Size Tile

private struct SizeTile: View {
    let size: Log.PoopSize
    let isSelected: Bool
    let action: () -> Void

    private var dotSize: CGFloat {
        switch size {
        case .small: return 12
        case .medium: return 18
        case .large: return 26
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Circle()
                    .fill(isSelected ? Theme.Colors.textOnGlass : Theme.Colors.textOnGlass.opacity(0.35))
                    .frame(width: dotSize, height: dotSize)
                    .frame(height: 30)

                Text(size.rawValue.capitalized)
                    .font(Theme.Fonts.captionBold(13))
                    .foregroundStyle(isSelected ? Theme.Colors.textOnGlass : Theme.Colors.textOnGlass.opacity(0.55))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? Color.white.opacity(0.7) : Color.white.opacity(0.35))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(isSelected ? 0.95 : 0.7), lineWidth: isSelected ? 1.5 : 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ManualEntryView(isPresented: .constant(true))
        .environmentObject(
            UserViewModel(
                user: User(name: "Brandon", age: 25, weight: 160, gender: "male"),
                withDummyData: true
            )
        )
}
