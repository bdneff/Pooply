//
//  DesignSystem.swift
//  Pooply
//
//  Design System v4 — Liquid Glass + Mesh Gradient
//  Icon-blue + warm orange mesh background, glass everything, dark text.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Theme

struct Theme {

    // MARK: - Colors

    struct Colors {
        // === Brand — Icon Blue (the exact candy blue from the app icon) ===
        static let iconBlue50  = Color(hex: "#E7F6FE")
        static let iconBlue100 = Color(hex: "#C7EAFB")
        static let iconBlue200 = Color(hex: "#9CDBF7")
        static let iconBlue300 = Color(hex: "#7BCEF3")
        static let iconBlue400 = Color(hex: "#5EC4F1")  // Hero icon blue
        static let iconBlue500 = Color(hex: "#3DAEDE")
        static let iconBlue600 = Color(hex: "#2C92BD")
        static let iconBlue700 = Color(hex: "#1F7397")

        // === Brand — Warm Beige/Tan (UI accents, NOT orange) ===
        // App is BLUE-dominant. Beige is the secondary warm accent — used for
        // selected states, slogan, dark accents. Orange palette below is kept
        // ONLY for log/data viz colors (hard stool = amber), NEVER for UI buttons.
        static let beige50  = Color(hex: "#FBF3E8")
        static let beige100 = Color(hex: "#F4E3CC")
        static let beige200 = Color(hex: "#E8D0AC")
        static let beige300 = Color(hex: "#D9B98A")
        static let beige400 = Color(hex: "#C8A06A")  // Hero beige
        static let beige500 = Color(hex: "#A87F4A")
        static let beige600 = Color(hex: "#86643A")
        static let beige700 = Color(hex: "#5E472A")

        // === Orange (DATA ONLY — for "hard stool" log category) ===
        // Do NOT use these for UI accents, buttons, or selected states.
        static let orange50  = Color(hex: "#FFF1E3")
        static let orange100 = Color(hex: "#FFDDB8")
        static let orange200 = Color(hex: "#FFC489")
        static let orange300 = Color(hex: "#FFAB5C")
        static let orange400 = Color(hex: "#F58A33")
        static let orange500 = Color(hex: "#E5731C")
        static let orange600 = Color(hex: "#C95C0F")
        static let orange700 = Color(hex: "#9F4708")

        // Primary aliases — BLUE is primary (mascot is blue), beige is secondary
        static let primary     = iconBlue400
        static let primaryDark = iconBlue500
        static let accent      = beige400

        // === Background — mesh-friendly base colors ===
        // Mesh uses iconBlue400 + orange400. These solid colors exist as fallbacks
        // when a view sits over a card and not directly on the mesh.
        static let background          = orange50    // Fallback solid for sheets/modals
        static let backgroundSecondary = iconBlue50
        static let cardBackground      = Color.white  // For sheets/modals only

        // === Mesh gradient anchor colors ===
        static let meshOrange = orange400
        static let meshBlue   = iconBlue400
        static let meshDeep   = iconBlue600   // Used for vignette / depth corners
        static let meshWarm   = orange300     // Light warm spot

        // === Accent Colors ===
        static let coral    = Color(hex: "#FF6B6B")
        static let amber    = Color(hex: "#FFB800")
        static let mint     = Color(hex: "#34D399")
        static let lavender = Color(hex: "#A78BFA")
        static let rose     = Color(hex: "#FB7185")
        static let peach    = orange300

        static let electric = Color(hex: "#FFF100")

        // === Pastel Day Card Colors (used by existing calendar code) ===
        static let pastelOlive    = Color(hex: "#D4D9A0")
        static let pastelMauve    = Color(hex: "#D4A9B8")
        static let pastelSky      = iconBlue200
        static let pastelLavender = Color(hex: "#C4B5D4")
        static let pastelSage     = Color(hex: "#B8D4B8")
        static let pastelPeach    = Color(hex: "#F0D0B0")
        static let pastelBlush    = Color(hex: "#E8C0C8")

        static let dayCardColors: [Color] = [
            pastelOlive, pastelMauve, pastelSky, pastelLavender,
            pastelSage, pastelPeach, pastelBlush
        ]

        // === Category Colors ===
        static let good  = mint
        static let hard  = orange400
        static let loose = iconBlue600       // Darker blue, distinct from mascot light blue
        static let blood = Color(hex: "#EF4444")

        // === Metric Colors ===
        static let hydration = iconBlue600   // Darker blue, distinct from mascot light blue
        static let fiber     = orange400     // Same warm orange as "hard" log — fiber is earthy
        static let warning   = coral

        // === Special POP accent — RESERVED for premium/Pro features ===
        // Same as the mascot/app logo blue. Use sparingly to keep it special.
        static let popBlue = iconBlue400

        // Semantic aliases
        static let green  = mint
        static let orange = orange400
        static let blue   = iconBlue400
        static let red    = blood
        static let yellow = amber

        // === Neutrals ===
        static let neutral50  = Color(hex: "#FAFAF8")
        static let neutral100 = Color(hex: "#F0EFEC")
        static let neutral200 = Color(hex: "#E2E0DC")
        static let neutral300 = Color(hex: "#CCC9C4")
        static let neutral400 = Color(hex: "#9B9792")
        static let neutral500 = Color(hex: "#6E6A65")
        static let neutral700 = Color(hex: "#3D3A36")
        static let neutral900 = Color(hex: "#1C1B19")

        // Legacy neutral aliases
        static let neutral      = neutral400
        static let neutralLight = neutral300
        static let neutralDark  = neutral700

        // === Text Colors ===
        // Dark text reads well on the mesh (orange warm zone) and on glass cards
        static let textPrimary   = Color(hex: "#1C1B19")
        static let textSecondary = Color(hex: "#5A554F")
        static let textTertiary  = Color(hex: "#8A847C")
        static let textOnPrimary = Color.white
        static let textOnBlue    = Color(hex: "#1C1B19")
        static let textDark      = Color(hex: "#1C1B19")
        static let textOnGlass   = Color(hex: "#1C1B19")  // Text rendered over glass cards
        static let textOnMesh    = Color(hex: "#1C1B19")  // Text rendered directly on mesh

        // === Card Accent Tints ===
        static let tealTint  = iconBlue50
        static let blueTint  = iconBlue50
        static let amberTint = Color(hex: "#FEF7E8")
        static let pinkTint  = Color(hex: "#FDE8EE")
        static let greenTint = Color(hex: "#E8F5EC")

        // === Tab Bar (legacy — still used by some old code paths) ===
        static let tabBarBackground = Color.white
        static let tabBarSelected   = neutral900
        static let tabBarUnselected = neutral400

        // === Legacy Blue Aliases (compat for views referencing skyBlue*) ===
        static let skyBlue50  = iconBlue50
        static let skyBlue100 = iconBlue100
        static let skyBlue200 = iconBlue200
        static let skyBlue300 = iconBlue300
        static let skyBlue400 = iconBlue400
        static let skyBlue500 = iconBlue500
        static let skyBlue600 = iconBlue600
        static let skyBlue700 = iconBlue700
        static let blue300 = iconBlue200
        static let blue400 = iconBlue300
        static let blue500 = iconBlue400
        static let blue600 = iconBlue500
        static let blue700 = iconBlue600
        static let blue800 = iconBlue700
        static let blue900 = neutral900
        static let blue50  = iconBlue50
        static let blue100 = iconBlue100

        // === Chart Colors ===
        static let chart1 = iconBlue400
        static let chart2 = mint
        static let chart3 = orange400
        static let chart4 = lavender
        static let chart5 = coral

        // === Gut Sense Ring Segment Colors (legacy compat) ===
        static let gutHydration   = iconBlue400
        static let gutFiber       = orange400
        static let gutConsistency = mint
        static let gutRegularity  = lavender
        static let gutBalance     = rose
    }

    // MARK: - Typography (Plus Jakarta Sans)

    struct Fonts {
        private static let extraBold = "PlusJakartaSans-ExtraBold"
        private static let bold      = "PlusJakartaSans-Bold"
        private static let semiBold  = "PlusJakartaSans-SemiBold"
        private static let medium    = "PlusJakartaSans-Medium"
        private static let regular   = "PlusJakartaSans-Regular"

        static func hero(_ size: CGFloat = 56) -> Font { .custom(extraBold, size: size) }
        static func title(_ size: CGFloat = 28) -> Font { .custom(bold, size: size) }
        static func heading(_ size: CGFloat = 20) -> Font { .custom(bold, size: size) }
        static func subheading(_ size: CGFloat = 18) -> Font { .custom(semiBold, size: size) }
        static func body(_ size: CGFloat = 16) -> Font { .custom(regular, size: size) }
        static func bodyBold(_ size: CGFloat = 16) -> Font { .custom(semiBold, size: size) }
        static func caption(_ size: CGFloat = 14) -> Font { .custom(regular, size: size) }
        static func captionBold(_ size: CGFloat = 14) -> Font { .custom(semiBold, size: size) }
        static func label(_ size: CGFloat = 12) -> Font { .custom(bold, size: size) }
        static func micro(_ size: CGFloat = 11) -> Font { .custom(medium, size: size) }
        static func metric(_ size: CGFloat = 32) -> Font { .custom(bold, size: size) }
    }

    // MARK: - Spacing

    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48

        static let screenHorizontal: CGFloat = 24
        static let screenVertical: CGFloat = 16
        static let cardPadding: CGFloat = 20
        static let cardPaddingSmall: CGFloat = 16
    }

    // MARK: - Radius

    struct Radius {
        static let small: CGFloat = 12
        static let medium: CGFloat = 16
        static let large: CGFloat = 20
        static let xl: CGFloat = 28
        static let pill: CGFloat = 100
        static let bottomCard: CGFloat = 32
        static let glass: CGFloat = 28   // default radius for glass cards
    }

    // MARK: - Shadows

    struct Shadows {
        static func card<V: View>(_ view: V) -> some View {
            view
                .compositingGroup()
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
                .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 1)
        }

        static func floating<V: View>(_ view: V) -> some View {
            view
                .compositingGroup()
                .shadow(color: Color.black.opacity(0.12), radius: 20, x: 0, y: 8)
                .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
        }

        static func subtle<V: View>(_ view: V) -> some View {
            view
                .compositingGroup()
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
        }

        static func glow<V: View>(_ view: V, color: Color = Colors.primary) -> some View {
            view
                .compositingGroup()
                .shadow(color: color.opacity(0.25), radius: 16, x: 0, y: 4)
        }

        static func neumorphic<V: View>(_ view: V) -> some View {
            view
                .compositingGroup()
                .shadow(color: Color.white.opacity(0.7), radius: 6, x: -3, y: -3)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 4, y: 4)
        }
    }

    // MARK: - Animation

    struct Animation {
        static let spring = SwiftUI.Animation.spring(response: 0.35, dampingFraction: 0.78)
        static let bouncy = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.65)
        static let quick = SwiftUI.Animation.easeOut(duration: 0.15)
        static let smooth = SwiftUI.Animation.easeInOut(duration: 0.25)
        static let snap = SwiftUI.Animation.spring(response: 0.25, dampingFraction: 0.85)
        static let tabSlide = SwiftUI.Animation.spring(response: 0.35, dampingFraction: 0.72)
        static let micro = SwiftUI.Animation.spring(response: 0.2, dampingFraction: 0.7)
        static let colorFlood = SwiftUI.Animation.easeOut(duration: 1.2)
        static let ringDraw = SwiftUI.Animation.spring(response: 0.6, dampingFraction: 0.7)
        static let press = SwiftUI.Animation.spring(response: 0.22, dampingFraction: 0.6)
    }

    // MARK: - Haptics

    struct Haptics {
        static func light()  { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
        static func medium() { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
        static func heavy()  { UIImpactFeedbackGenerator(style: .heavy).impactOccurred() }
        static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
        static func selection() { UISelectionFeedbackGenerator().selectionChanged() }
    }
}

// MARK: - Frosted Sheet Background (for all modal sheets)

/// Modal sheet background — soft beige whisper at top → gray base.
/// Used on LogOptions, Profile, EditProfile, Export, Notification sheets.
/// Pair with `.presentationBackground(.clear)`.
struct FrostedSheetBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(hex: "#F8EFE3"),  // soft warm beige whisper at top
                Color(hex: "#F4F2EE"),  // mid blend
                Color(hex: "#EFEDE8")   // gray base
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

/// Insights tab background — same beige→gray gradient as modals (no blue).
/// Heroes the warm/clean aesthetic for the data view.
struct InsightsBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(hex: "#F8EFE3"),
                Color(hex: "#F4F2EE"),
                Color(hex: "#EFEDE8")
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

// MARK: - Mesh Background

/// Static pastel orange→blue mesh. Owns Home + Insights backgrounds.
/// Intentionally non-animated so Liquid Glass can sample it cleanly.
struct MeshBackground: View {
    private var meshPoints: [SIMD2<Float>] {
        [
            SIMD2(0.0, 0.0), SIMD2(0.5, 0.0), SIMD2(1.0, 0.0),
            SIMD2(0.0, 0.5), SIMD2(0.5, 0.5), SIMD2(1.0, 0.5),
            SIMD2(0.0, 1.0), SIMD2(0.5, 1.0), SIMD2(1.0, 1.0)
        ]
    }

    private var meshColors: [Color] {
        // Soft beige + modal-gray whisper top → white middle → icon-blue bottom.
        [
            Color(hex: "#F8EFE3"),    Color(hex: "#F4F2EE"),    Color(hex: "#F8EFE3"),
            Theme.Colors.beige50,     Color.white,              Theme.Colors.iconBlue100,
            Theme.Colors.iconBlue500, Theme.Colors.iconBlue400, Theme.Colors.iconBlue300
        ]
    }

    var body: some View {
        MeshGradient(width: 3, height: 3, points: meshPoints, colors: meshColors)
            .ignoresSafeArea()
    }
}

// MARK: - Liquid Glass Primitive

/// Pooply's signature frosted-glass surface.
/// One unified recipe — looks identical on iOS 15 through iOS 26.
/// Layers: ultraThinMaterial blur → strong white tint → top highlight gradient → border stroke.
struct GlassSurface: ViewModifier {
    var radius: CGFloat = Theme.Radius.glass
    var tint: Color? = nil
    var stroke: Bool = true

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)

        content
            .background(frostedFill(shape: shape))
            .overlay(borderStroke(shape: shape))
            .clipShape(shape)
    }

    private func frostedFill(shape: RoundedRectangle) -> some View {
        ZStack {
            // 1. Material blur (refracts what's behind, slightly)
            shape.fill(.ultraThinMaterial)

            // 2. Strong white tint — gives the clean, light frosted look
            shape.fill(Color.white.opacity(0.55))

            // 3. Optional color tint for accent cards
            if let tint {
                shape.fill(tint.opacity(0.10))
            }

            // 4. Top-to-bottom highlight — subtle inner shine
            shape.fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.55),
                        Color.white.opacity(0.10),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .center
                )
            )

            // 5. Bottom-left soft glow (catches the mesh color subtly)
            shape.fill(
                RadialGradient(
                    colors: [
                        Color.white.opacity(0.18),
                        Color.clear
                    ],
                    center: .init(x: 0.15, y: 0.85),
                    startRadius: 0,
                    endRadius: 80
                )
            )
        }
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func borderStroke(shape: RoundedRectangle) -> some View {
        if stroke {
            // Solid white border. Visible/thick enough to make cards pop crisply.
            shape.stroke(Color.white, lineWidth: 2)
        }
    }
}

extension View {
    /// Apply Pooply's Liquid Glass surface (iOS 26 real, iOS 18 material fallback).
    func glassSurface(
        radius: CGFloat = Theme.Radius.glass,
        tint: Color? = nil,
        stroke: Bool = true
    ) -> some View {
        modifier(GlassSurface(radius: radius, tint: tint, stroke: stroke))
    }
}

// MARK: - GlassCard

/// Padded glass container. Use for metric cards, info panels, etc.
struct GlassCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = Theme.Spacing.cardPadding
    var radius: CGFloat = Theme.Radius.glass
    var tint: Color? = nil

    init(padding: CGFloat = Theme.Spacing.cardPadding,
         radius: CGFloat = Theme.Radius.glass,
         tint: Color? = nil,
         @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.radius = radius
        self.tint = tint
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .glassSurface(radius: radius, tint: tint)
    }
}

// MARK: - GlassPill (bottom-left nav selector)

struct GlassPill<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(.horizontal, 6)
            .padding(.vertical, 6)
            .glassSurface(radius: Theme.Radius.pill)
    }
}

// MARK: - GlassFAB (bottom-right log button)

struct GlassFAB: View {
    let action: () -> Void
    @State private var pressed: Bool = false

    var body: some View {
        Button {
            Theme.Haptics.medium()
            action()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 26, weight: .heavy))
                .foregroundStyle(.white)
                .scaleEffect(pressed ? 0.85 : 1.0)
                .rotationEffect(.degrees(pressed ? -8 : 0))
                .frame(width: 64, height: 64)
                .background(Circle().fill(Theme.Colors.neutral900))
                .scaleEffect(pressed ? 0.92 : 1.0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { isPressing in
            withAnimation(Theme.Animation.press) {
                pressed = isPressing
            }
        }, perform: {})
        .shadow(color: Color.black.opacity(0.20), radius: 12, x: 0, y: 6)
    }
}

// MARK: - GlassNavPill (Home / Insights selector)

enum AppPage: Hashable, CaseIterable {
    case home
    case insights

    var label: String {
        switch self {
        case .home: return "Home"
        case .insights: return "Data"
        }
    }

    var iconFilled: String {
        switch self {
        case .home: return "house.fill"
        case .insights: return "chart.bar.fill"
        }
    }

    var iconOutline: String {
        switch self {
        case .home: return "house"
        case .insights: return "chart.bar"
        }
    }
}

struct GlassNavPill: View {
    @Binding var selected: AppPage
    @Namespace private var ns

    var body: some View {
        HStack(spacing: 4) {
            ForEach(AppPage.allCases, id: \.self) { page in
                Button {
                    Theme.Haptics.selection()
                    withAnimation(Theme.Animation.tabSlide) {
                        selected = page
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: selected == page ? page.iconFilled : page.iconOutline)
                            .font(.system(size: 15, weight: .bold))
                            .symbolEffect(.bounce, value: selected == page)
                        Text(page.label)
                            .font(Theme.Fonts.captionBold(13))
                    }
                    .foregroundStyle(selected == page ? .white : Color.white.opacity(0.45))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        ZStack {
                            if selected == page {
                                Capsule()
                                    .fill(Color.white.opacity(0.15))
                                    .matchedGeometryEffect(id: "pill_selection", in: ns)
                            }
                        }
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
        .background(
            Capsule().fill(Theme.Colors.neutral900)
        )
        .shadow(color: Color.black.opacity(0.18), radius: 14, x: 0, y: 6)
    }
}

// MARK: - Reusable Components (legacy compat + new)

/// Standard card container — now glass-backed
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
            .glassSurface(radius: radius)
    }
}

/// Tinted accent card (legacy)
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
            .glassSurface(radius: radius, tint: tint)
    }
}

/// Mini stat card for metrics — glass-backed
struct StatCard: View {
    let value: String
    let label: String
    let icon: String?
    let iconColor: Color
    var valueColor: Color = Theme.Colors.textOnGlass
    var showRing: Bool = false
    var ringProgress: CGFloat = 0
    var ringColor: Color = Theme.Colors.primary

    init(value: String,
         label: String,
         icon: String? = nil,
         iconColor: Color = Theme.Colors.primary,
         valueColor: Color = Theme.Colors.textOnGlass,
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
                    Circle()
                        .stroke(ringColor.opacity(0.15), lineWidth: 4)
                    Circle()
                        .trim(from: 0, to: ringProgress)
                        .stroke(ringColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }

                if let iconName = icon {
                    Image(systemName: iconName)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(iconColor)
                }
            }
            .frame(width: 52, height: 52)

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
        .glassSurface(radius: Theme.Radius.medium)
    }
}

/// Primary action button — orange, dark text
struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var icon: String? = nil
    var isLoading: Bool = false

    var body: some View {
        Button(action: {
            Theme.Haptics.medium()
            action()
        }) {
            HStack(spacing: Theme.Spacing.sm) {
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    if let iconName = icon {
                        Image(systemName: iconName)
                            .font(.system(size: 16, weight: .bold))
                    }
                    Text(title)
                        .font(Theme.Fonts.bodyBold())
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Theme.Colors.primary)
            .clipShape(Capsule())
        }
        .disabled(isLoading)
    }
}

/// Secondary glass button
struct SecondaryButton: View {
    let title: String
    let action: () -> Void
    var icon: String? = nil

    var body: some View {
        Button(action: {
            Theme.Haptics.light()
            action()
        }) {
            HStack(spacing: Theme.Spacing.sm) {
                if let iconName = icon {
                    Image(systemName: iconName)
                        .font(.system(size: 16, weight: .bold))
                }
                Text(title)
                    .font(Theme.Fonts.bodyBold())
            }
            .foregroundStyle(Theme.Colors.textOnGlass)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .glassSurface(radius: Theme.Radius.pill)
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
        Button(action: {
            Theme.Haptics.selection()
            action()
        }) {
            Text(title)
                .font(Theme.Fonts.captionBold())
                .foregroundStyle(isSelected ? .white : Theme.Colors.textOnGlass.opacity(0.6))
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
                .background(
                    Group {
                        if isSelected {
                            Capsule().fill(Color.white.opacity(0.85))
                        } else {
                            Capsule().fill(.ultraThinMaterial)
                        }
                    }
                )
        }
    }
}

/// Section header
struct SectionHeader: View {
    let title: String
    var action: (() -> Void)? = nil
    var actionTitle: String = "See All"
    var onDark: Bool = false

    var body: some View {
        HStack {
            Text(title)
                .font(Theme.Fonts.heading())
                .foregroundStyle(onDark ? .white : Theme.Colors.textOnGlass)

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

/// Close button for modals — glass
struct CloseButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: {
            Theme.Haptics.light()
            action()
        }) {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Theme.Colors.textOnGlass)
                .frame(width: 36, height: 36)
                .glassSurface(radius: 18)
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

// MARK: - Mascot Avatar (top-right of Home)

/// Circular avatar using the app logo (blue). Solid white ring, subtle shadow.
struct MascotAvatar: View {
    var size: CGFloat = 52
    let action: () -> Void
    @State private var pressed: Bool = false

    var body: some View {
        Button {
            Theme.Haptics.light()
            action()
        } label: {
            Image("appLogo")
                .resizable()
                .scaledToFill()
                .frame(width: size - 6, height: size - 6)
                .clipShape(Circle())
                .padding(3)
                .background(Circle().fill(Color.white))
                .scaleEffect(pressed ? 0.94 : 1.0)
        }
        .buttonStyle(.plain)
        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { isPressing in
            withAnimation(Theme.Animation.press) {
                pressed = isPressing
            }
        }, perform: {})
    }
}

/// Legacy mascot circle (used in old code paths) — kept for compat
struct MascotCircle: View {
    var size: CGFloat = 44

    var body: some View {
        Image("lee")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .clipShape(Circle())
    }
}

// MARK: - Elevated Button Style (3D press)

struct ElevatedButtonStyle: ButtonStyle {
    var color: Color = Theme.Colors.primary
    var height: CGFloat = 56

    private var darkerColor: Color { color.opacity(0.7) }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(
                ZStack {
                    Capsule()
                        .fill(darkerColor)
                        .offset(y: configuration.isPressed ? 0 : 4)
                    Capsule()
                        .fill(color)
                        .offset(y: configuration.isPressed ? 2 : 0)
                }
            )
            .foregroundStyle(.white)
            .offset(y: configuration.isPressed ? 2 : 0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

extension View {
    func elevatedButtonStyle(color: Color = Theme.Colors.primary, height: CGFloat = 56) -> some View {
        self.buttonStyle(ElevatedButtonStyle(color: color, height: height))
    }
}

// MARK: - Bouncy Button Style

struct BouncyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(Theme.Animation.micro, value: configuration.isPressed)
    }
}

// MARK: - View Modifiers

extension View {
    func screenPadding() -> some View {
        self.padding(.horizontal, Theme.Spacing.screenHorizontal)
    }

    func bouncyButton() -> some View {
        self.buttonStyle(BouncyButtonStyle())
    }

    /// Legacy neumorphic shadow — kept for compat with un-rewritten views
    func neumorphicShadow() -> some View {
        self
            .compositingGroup()
            .shadow(color: Color.white.opacity(0.7), radius: 6, x: -3, y: -3)
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 4, y: 4)
    }
}

// Note: cardShadow(), floatingShadow(), subtleShadow() are defined in Extensions.swift

// MARK: - Preview

#Preview("Design System v4") {
    ZStack {
        MeshBackground()

        ScrollView {
            VStack(spacing: 24) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Nice to see you,")
                            .font(Theme.Fonts.body())
                            .foregroundStyle(Theme.Colors.textOnMesh.opacity(0.7))
                        Text("Brandon")
                            .font(Theme.Fonts.title())
                            .foregroundStyle(Theme.Colors.textOnMesh)
                    }
                    Spacer()
                    MascotAvatar { }
                }

                VStack(spacing: 8) {
                    Text("Poop Score")
                        .font(Theme.Fonts.subheading())
                        .foregroundStyle(Theme.Colors.textOnMesh)
                    Text("88")
                        .font(Theme.Fonts.hero(140))
                        .foregroundStyle(Theme.Colors.textOnMesh)
                }
                .padding(.vertical, 32)

                HStack(spacing: 12) {
                    GlassCard {
                        VStack(spacing: 4) {
                            Text("72%").font(Theme.Fonts.heading())
                            Text("HYDRATION").font(Theme.Fonts.label(10))
                                .foregroundStyle(Theme.Colors.textTertiary)
                        }
                    }
                    GlassCard {
                        VStack(spacing: 4) {
                            Text("48%").font(Theme.Fonts.heading())
                            Text("FIBER").font(Theme.Fonts.label(10))
                                .foregroundStyle(Theme.Colors.textTertiary)
                        }
                    }
                    GlassCard {
                        VStack(spacing: 4) {
                            Text("0%").font(Theme.Fonts.heading())
                            Text("BLOOD").font(Theme.Fonts.label(10))
                                .foregroundStyle(Theme.Colors.textTertiary)
                        }
                    }
                }

                HStack {
                    GlassNavPill(selected: .constant(.home))
                    Spacer()
                    GlassFAB { }
                }
                .padding(.top, 32)
            }
            .padding(Theme.Spacing.screenHorizontal)
        }
    }
}
