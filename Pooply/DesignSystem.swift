//
//  DesignSystem.swift
//  Pooply
//
//  Design System for Pooply UI
//  Apple Editors' Choice Quality | Feminine, Minimal, Colorful
//

import SwiftUI

// MARK: - Theme

struct Theme {

    // MARK: - Colors

    struct Colors {
        // Backgrounds
        static let background = Color(hex: "#F1F5EC")
        static let backgroundSecondary = Color(hex: "#F8FAF9")
        static let cardBackground = Color.white

        // Brand Colors
        static let primary = Color(hex: "#19B888")        // Pooply Teal
        static let primaryLight = Color(hex: "#4ECBA0")   // Lighter teal
        static let secondary = Color(hex: "#2E7D32")      // Forest Green
        static let accent = Color(hex: "#1B5E20")         // Dark Forest

        // Category Colors
        static let good = Color(hex: "#19B888")           // Teal - Regular/Good
        static let hard = Color(hex: "#FF7A33")           // Warm Amber
        static let loose = Color(hex: "#008CFF")          // Sky Blue
        static let blood = Color(hex: "#E53935")          // Red Alert

        // Metric Colors
        static let hydration = Color(hex: "#4FC3F7")      // Light Blue
        static let fiber = Color(hex: "#FFB74D")          // Warm Yellow/Wheat
        static let warning = Color(hex: "#FFA726")        // Orange

        // Semantic Color Aliases (for insights)
        static let green = good                           // Success/Positive
        static let orange = hard                          // Warning/Caution
        static let blue = hydration                       // Info/Water
        static let red = blood                            // Alert/Danger
        static let yellow = fiber                         // Highlight/Milestone

        // Neutral Colors
        static let neutral = Color(hex: "#78909C")        // Gray
        static let neutralLight = Color(hex: "#B0BEC5")   // Light Gray
        static let neutralDark = Color(hex: "#546E7A")    // Dark Gray

        // Card Accent Tints (10% opacity feel)
        static let tealTint = Color(hex: "#E8F5F1")
        static let blueTint = Color(hex: "#E3F2FD")
        static let amberTint = Color(hex: "#FFF3E0")
        static let pinkTint = Color(hex: "#FCE4EC")
        static let greenTint = Color(hex: "#E8F5E9")

        // Text Colors
        static let textPrimary = Color(hex: "#1B5E20")
        static let textSecondary = Color(hex: "#2E7D32")
        static let textTertiary = Color(hex: "#78909C")
        static let textOnPrimary = Color.white
        static let textDark = Color(hex: "#1F1F1F")

        // Tab Bar
        static let tabBarBackground = Color(hex: "#F5F5F5")
        static let tabBarSelected = Color(hex: "#19B888")
        static let tabBarUnselected = Color(hex: "#78909C")
    }

    // MARK: - Typography

    struct Fonts {
        // Font Names
        private static let black = "Nunito-Black"
        private static let bold = "Nunito-Bold"
        private static let regular = "Nunito-Regular"

        // Hero - Large numbers (Poop Score)
        static func hero(_ size: CGFloat = 52) -> Font {
            .custom(black, size: size)
        }

        // Title - Page titles
        static func title(_ size: CGFloat = 28) -> Font {
            .custom(bold, size: size)
        }

        // Heading - Section headers
        static func heading(_ size: CGFloat = 20) -> Font {
            .custom(bold, size: size)
        }

        // Subheading - Card titles
        static func subheading(_ size: CGFloat = 18) -> Font {
            .custom(bold, size: size)
        }

        // Body - Regular text
        static func body(_ size: CGFloat = 16) -> Font {
            .custom(regular, size: size)
        }

        // Body Bold
        static func bodyBold(_ size: CGFloat = 16) -> Font {
            .custom(bold, size: size)
        }

        // Caption - Secondary text
        static func caption(_ size: CGFloat = 14) -> Font {
            .custom(regular, size: size)
        }

        // Caption Bold
        static func captionBold(_ size: CGFloat = 14) -> Font {
            .custom(bold, size: size)
        }

        // Label - Small labels (uppercase)
        static func label(_ size: CGFloat = 12) -> Font {
            .custom(bold, size: size)
        }

        // Micro - Very small text
        static func micro(_ size: CGFloat = 11) -> Font {
            .custom(regular, size: size)
        }
    }

    // MARK: - Spacing

    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48

        // Screen padding
        static let screenHorizontal: CGFloat = 20
        static let screenVertical: CGFloat = 16

        // Card padding
        static let cardPadding: CGFloat = 20
        static let cardPaddingSmall: CGFloat = 16
    }

    // MARK: - Radius

    struct Radius {
        static let small: CGFloat = 12
        static let medium: CGFloat = 16
        static let large: CGFloat = 20
        static let xl: CGFloat = 24
        static let pill: CGFloat = 100
    }

    // MARK: - Shadows

    struct Shadows {
        // Card shadow
        static func card<V: View>(_ view: V) -> some View {
            view
                .compositingGroup()
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 6)
        }

        // Floating element shadow (FAB, tab bar)
        static func floating<V: View>(_ view: V) -> some View {
            view
                .compositingGroup()
                .shadow(color: Color.black.opacity(0.1), radius: 16, x: 0, y: 8)
        }

        // Subtle shadow for inner elements
        static func subtle<V: View>(_ view: V) -> some View {
            view
                .compositingGroup()
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
        }
    }

    // MARK: - Animation

    struct Animation {
        static let spring = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.82)
        static let quick = SwiftUI.Animation.easeOut(duration: 0.15)
        static let smooth = SwiftUI.Animation.easeInOut(duration: 0.25)
        static let snap = SwiftUI.Animation.spring(response: 0.25, dampingFraction: 0.85)
    }
}

// MARK: - Reusable Components

/// Standard card container with shadow
struct CardView<Content: View>: View {
    let content: Content
    var padding: CGFloat = Theme.Spacing.cardPadding
    var radius: CGFloat = Theme.Radius.large

    init(padding: CGFloat = Theme.Spacing.cardPadding,
         radius: CGFloat = Theme.Radius.large,
         @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.radius = radius
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(Theme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .cardShadow()
    }
}

/// Tinted accent card (no shadow, colored background)
struct AccentCard<Content: View>: View {
    let tint: Color
    let content: Content
    var padding: CGFloat = Theme.Spacing.cardPaddingSmall
    var radius: CGFloat = Theme.Radius.medium

    init(tint: Color,
         padding: CGFloat = Theme.Spacing.cardPaddingSmall,
         radius: CGFloat = Theme.Radius.medium,
         @ViewBuilder content: () -> Content) {
        self.tint = tint
        self.padding = padding
        self.radius = radius
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(tint)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}

/// Mini stat card for metrics display
struct StatCard: View {
    let value: String
    let label: String
    let icon: String?
    let iconColor: Color
    var valueColor: Color = Theme.Colors.textPrimary
    var showRing: Bool = false
    var ringProgress: CGFloat = 0
    var ringColor: Color = Theme.Colors.primary

    init(value: String,
         label: String,
         icon: String? = nil,
         iconColor: Color = Theme.Colors.primary,
         valueColor: Color = Theme.Colors.textPrimary,
         showRing: Bool = false,
         ringProgress: CGFloat = 0,
         ringColor: Color = Theme.Colors.primary) {
        self.value = value
        self.label = label
        self.icon = icon
        self.iconColor = iconColor
        self.valueColor = valueColor
        self.showRing = showRing
        self.ringProgress = ringProgress
        self.ringColor = ringColor
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            ZStack {
                if showRing {
                    // Background ring
                    Circle()
                        .stroke(ringColor.opacity(0.2), lineWidth: 4)

                    // Progress ring
                    Circle()
                        .trim(from: 0, to: ringProgress)
                        .stroke(ringColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }

                if let iconName = icon {
                    Image(iconName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .opacity(0.6)
                }
            }
            .frame(width: 56, height: 56)

            VStack(spacing: 2) {
                Text(value)
                    .font(Theme.Fonts.heading(22))
                    .foregroundStyle(valueColor)
                    .contentTransition(.numericText())

                Text(label.uppercased())
                    .font(Theme.Fonts.label(10))
                    .foregroundStyle(Theme.Colors.textTertiary)
                    .tracking(0.5)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.md)
        .background(Theme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous))
        .cardShadow()
    }
}

/// Primary action button
struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var icon: String? = nil
    var isLoading: Bool = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    if let iconName = icon {
                        Image(systemName: iconName)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    Text(title)
                        .font(Theme.Fonts.bodyBold())
                }
            }
            .foregroundStyle(Theme.Colors.textOnPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Theme.Colors.primary)
            .clipShape(Capsule())
        }
        .disabled(isLoading)
    }
}

/// Secondary button (outline style)
struct SecondaryButton: View {
    let title: String
    let action: () -> Void
    var icon: String? = nil

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.sm) {
                if let iconName = icon {
                    Image(systemName: iconName)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(Theme.Fonts.bodyBold())
            }
            .foregroundStyle(Theme.Colors.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Theme.Colors.cardBackground)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Theme.Colors.primary, lineWidth: 2)
            )
        }
    }
}

/// Chip/Tag selector
struct ChipSelector: View {
    let options: [String]
    @Binding var selected: String

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ForEach(options, id: \.self) { option in
                ChipButton(
                    title: option,
                    isSelected: selected == option,
                    action: { selected = option }
                )
            }
        }
    }
}

struct ChipButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.Fonts.captionBold())
                .foregroundStyle(isSelected ? Theme.Colors.textOnPrimary : Theme.Colors.textTertiary)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
                .background(isSelected ? Theme.Colors.primary : Theme.Colors.tabBarBackground)
                .clipShape(Capsule())
        }
    }
}

/// Section header with optional action
struct SectionHeader: View {
    let title: String
    var action: (() -> Void)? = nil
    var actionTitle: String = "See All"

    var body: some View {
        HStack {
            Text(title)
                .font(Theme.Fonts.heading())
                .foregroundStyle(Theme.Colors.textPrimary)

            Spacer()

            if let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(Theme.Fonts.captionBold())
                        .foregroundStyle(Theme.Colors.primary)
                }
            }
        }
    }
}

/// Close button for modals
struct CloseButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Theme.Colors.textDark)
                .frame(width: 32, height: 32)
                .background(Theme.Colors.backgroundSecondary)
                .clipShape(Circle())
        }
    }
}

/// Category indicator dot
struct CategoryDot: View {
    let category: Log.PoopCategory
    var size: CGFloat = 10

    var color: Color {
        switch category {
        case .regular: return Theme.Colors.good
        case .hard: return Theme.Colors.hard
        case .loose: return Theme.Colors.loose
        }
    }

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
    }
}

// MARK: - Mascot Circle

struct MascotCircle: View {
    var size: CGFloat = 44

    var body: some View {
        Image("pooplyMascot")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .background(Theme.Colors.primary.gradient)
            .clipShape(Circle())
    }
}

// MARK: - Elevated Button Style (Duolingo-style 3D press)

struct ElevatedButtonStyle: ButtonStyle {
    var color: Color = Theme.Colors.primary
    var height: CGFloat = 56

    private var darkerColor: Color {
        color.opacity(0.7)
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(
                ZStack {
                    // Bottom shadow layer (darker)
                    Capsule()
                        .fill(darkerColor)
                        .offset(y: configuration.isPressed ? 0 : 4)

                    // Top face layer
                    Capsule()
                        .fill(color)
                        .offset(y: configuration.isPressed ? 2 : 0)
                }
            )
            .foregroundStyle(Theme.Colors.textOnPrimary)
            .offset(y: configuration.isPressed ? 2 : 0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

extension View {
    /// Apply the elevated Duolingo-style 3D button look
    func elevatedButtonStyle(color: Color = Theme.Colors.primary, height: CGFloat = 56) -> some View {
        self.buttonStyle(ElevatedButtonStyle(color: color, height: height))
    }
}

// MARK: - View Modifiers

extension View {
    /// Screen padding helper
    func screenPadding() -> some View {
        self.padding(.horizontal, Theme.Spacing.screenHorizontal)
    }
}

// Note: cardShadow(), floatingShadow(), subtleShadow() are defined in Extensions.swift

// MARK: - Preview

#Preview("Design System") {
    ScrollView {
        VStack(spacing: 24) {
            // Typography
            VStack(alignment: .leading, spacing: 8) {
                Text("Typography")
                    .font(Theme.Fonts.heading())
                Text("Hero 52pt").font(Theme.Fonts.hero())
                Text("Title 28pt").font(Theme.Fonts.title())
                Text("Heading 20pt").font(Theme.Fonts.heading())
                Text("Body 16pt").font(Theme.Fonts.body())
                Text("Caption 14pt").font(Theme.Fonts.caption())
                Text("LABEL 12PT").font(Theme.Fonts.label())
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            // Colors
            VStack(alignment: .leading, spacing: 8) {
                Text("Colors")
                    .font(Theme.Fonts.heading())
                HStack(spacing: 8) {
                    Circle().fill(Theme.Colors.primary).frame(width: 40, height: 40)
                    Circle().fill(Theme.Colors.good).frame(width: 40, height: 40)
                    Circle().fill(Theme.Colors.hard).frame(width: 40, height: 40)
                    Circle().fill(Theme.Colors.loose).frame(width: 40, height: 40)
                    Circle().fill(Theme.Colors.blood).frame(width: 40, height: 40)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            // Components
            VStack(spacing: 16) {
                Text("Components")
                    .font(Theme.Fonts.heading())
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 12) {
                    StatCard(value: "72%", label: "Hydration", icon: "water", iconColor: Theme.Colors.hydration, showRing: true, ringProgress: 0.72, ringColor: Theme.Colors.hydration)
                    StatCard(value: "0%", label: "Blood", icon: "blood", iconColor: Theme.Colors.blood, showRing: true, ringProgress: 0, ringColor: Theme.Colors.blood)
                }

                PrimaryButton(title: "Save Log", action: {})
                SecondaryButton(title: "Cancel", action: {})
            }
        }
        .padding()
    }
    .background(Theme.Colors.background)
}
