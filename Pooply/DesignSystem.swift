//
//  DesignSystem.swift
//  Pooply
//
//  Design System v5 — Tiimo-minimal:
//  cream surface, baby blue (logo) + caramel (mascot) brand colors,
//  surgical frosted glass only on tab bar / FAB / contained data widgets.
//  Espresso brown text. Bristol data palette used ONLY in data viz.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Theme

struct Theme {

    // MARK: - Colors

    struct Colors {
        // === Brand: Baby Blue (from app logo) ===
        static let babyBlue50  = Color(hex: "#EEF7FC")
        static let babyBlue100 = Color(hex: "#D7ECF7")
        static let babyBlue200 = Color(hex: "#B7DEEF")
        static let babyBlue300 = Color(hex: "#92CDE6")
        static let babyBlue400 = Color(hex: "#8ADBFF")  // hero baby blue
        static let babyBlue500 = Color(hex: "#4DA4C9")
        static let babyBlue600 = Color(hex: "#3589B0")
        static let babyBlue700 = Color(hex: "#266F92")

        // === Brand: Caramel/Tan (from mascot) ===
        static let caramel50  = Color(hex: "#FAF1E2")
        static let caramel100 = Color(hex: "#F3DCB9")
        static let caramel200 = Color(hex: "#E9C390")
        static let caramel300 = Color(hex: "#DCA968")
        static let caramel400 = Color(hex: "#C68F4A")  // mascot tone
        static let caramel500 = Color(hex: "#A87538")
        static let caramel600 = Color(hex: "#855B2A")
        static let caramel700 = Color(hex: "#5F4220")

        // === Surface: Cream ===
        static let cream      = Color(hex: "#F6F1E7")
        static let creamSoft  = Color(hex: "#FBF7EE")
        static let paper      = Color(hex: "#FFFCF6")

        // === Text: Espresso (deep warm brown, not black) ===
        static let espresso       = Color(hex: "#2A201A")
        static let espressoMid    = Color(hex: "#5C4E44")
        static let espressoLight  = Color(hex: "#8C8077")

        // === Data Colors — modern vivid palette. Used ONLY in data viz. Never chrome. ===
        // Inspired by Superpower-style biomarker palette: mint + lemon + bubblegum + sky.
        static let dataGreen   = Color(hex: "#5AD9A1")  // mint, Bristol 3-4 healthy
        static let dataYellow  = Color(hex: "#F0E869")  // lemon, Bristol 5 caution / "okay"
        static let dataPink    = Color(hex: "#F4A5C8")  // bubblegum, Bristol 1-2 hard
        static let dataBlue    = Color(hex: "#7FC8E0")  // sky, Bristol 6 loose
        static let dataLiquid  = Color(hex: "#4A95B8")  // deeper blue, Bristol 7 watery

        // Legacy data aliases — old code uses these names, point at new colors.
        static let dataAmber   = dataYellow
        static let dataCoral   = dataPink
        static let dataLoose   = dataBlue

        // === Semantic primaries ===
        static let primary     = babyBlue400
        static let primaryDark = babyBlue600
        static let accent      = caramel400
        static let background  = cream
        static let surface     = paper

        // Brand pop blue — reserved for premium accents (Pro etc)
        static let popBlue = babyBlue400

        // === Log categories — use data palette ===
        static let good   = dataGreen
        static let hard   = dataCoral
        static let loose  = dataLoose
        static let blood  = Color(hex: "#EF4444")
        static let amber  = dataAmber
        static let mint   = dataGreen
        static let coral  = dataCoral

        // === Metric colors (legacy compat) ===
        static let hydration = dataLoose
        static let fiber     = caramel500
        static let warning   = dataCoral
        static let lavender  = Color(hex: "#A78BFA")
        static let rose      = Color(hex: "#FB7185")
        static let peach     = caramel300
        static let electric  = Color(hex: "#FFF100")

        // === Neutrals ===
        static let neutral50  = Color(hex: "#FAFAF8")
        static let neutral100 = Color(hex: "#F0EFEC")
        static let neutral200 = Color(hex: "#E2E0DC")
        static let neutral300 = Color(hex: "#CCC9C4")
        static let neutral400 = Color(hex: "#9B9792")
        static let neutral500 = Color(hex: "#6E6A65")
        static let neutral700 = Color(hex: "#3D3A36")
        static let neutral900 = Color(hex: "#1A1612")  // FAB / button "black"

        static let neutral      = neutral400
        static let neutralLight = neutral300
        static let neutralDark  = neutral700

        // === Text aliases (legacy compat) ===
        static let textPrimary    = espresso
        static let textSecondary  = espressoMid
        static let textTertiary   = espressoLight
        static let textOnPrimary  = Color.white
        static let textOnBlue     = espresso
        static let textDark       = espresso
        static let textOnGlass    = espresso
        static let textOnMesh     = espresso

        // === Background aliases (legacy compat) ===
        static let backgroundSecondary = creamSoft
        static let cardBackground      = paper

        // === Mesh tokens (legacy compat — we don't use mesh anymore) ===
        static let meshOrange = caramel400
        static let meshBlue   = babyBlue400
        static let meshDeep   = babyBlue600
        static let meshWarm   = caramel300

        // === Card tints (legacy compat) ===
        static let tealTint   = babyBlue50
        static let blueTint   = babyBlue50
        static let amberTint  = Color(hex: "#FEF7E8")
        static let pinkTint   = Color(hex: "#FDE8EE")
        static let greenTint  = Color(hex: "#E8F5EC")

        // === Tab bar (legacy compat) ===
        static let tabBarBackground = paper
        static let tabBarSelected   = espresso
        static let tabBarUnselected = espressoLight

        // === Pastel day card colors (calendar) ===
        static let pastelOlive    = Color(hex: "#D4D9A0")
        static let pastelMauve    = Color(hex: "#D4A9B8")
        static let pastelSky      = babyBlue200
        static let pastelLavender = Color(hex: "#C4B5D4")
        static let pastelSage     = Color(hex: "#B8D4B8")
        static let pastelPeach    = caramel200
        static let pastelBlush    = Color(hex: "#E8C0C8")

        static let dayCardColors: [Color] = [
            pastelOlive, pastelMauve, pastelSky, pastelLavender,
            pastelSage, pastelPeach, pastelBlush
        ]

        // === Chart palette ===
        static let chart1 = babyBlue400
        static let chart2 = dataGreen
        static let chart3 = caramel400
        static let chart4 = lavender
        static let chart5 = dataCoral

        // === Gut sense ring (legacy compat) ===
        static let gutHydration   = dataLoose
        static let gutFiber       = caramel500
        static let gutConsistency = dataGreen
        static let gutRegularity  = lavender
        static let gutBalance     = rose

        // === Legacy iconBlue / beige / orange aliases ===
        static let iconBlue50  = babyBlue50
        static let iconBlue100 = babyBlue100
        static let iconBlue200 = babyBlue200
        static let iconBlue300 = babyBlue300
        static let iconBlue400 = babyBlue400
        static let iconBlue500 = babyBlue500
        static let iconBlue600 = babyBlue600
        static let iconBlue700 = babyBlue700

        static let beige50  = caramel50
        static let beige100 = caramel100
        static let beige200 = caramel200
        static let beige300 = caramel300
        static let beige400 = caramel400
        static let beige500 = caramel500
        static let beige600 = caramel600
        static let beige700 = caramel700

        static let orange50  = Color(hex: "#FFF1E3")
        static let orange100 = Color(hex: "#FFDDB8")
        static let orange200 = Color(hex: "#FFC489")
        static let orange300 = caramel300
        static let orange400 = dataCoral
        static let orange500 = Color(hex: "#E5731C")
        static let orange600 = Color(hex: "#C95C0F")
        static let orange700 = Color(hex: "#9F4708")

        static let skyBlue50  = babyBlue50
        static let skyBlue100 = babyBlue100
        static let skyBlue200 = babyBlue200
        static let skyBlue300 = babyBlue300
        static let skyBlue400 = babyBlue400
        static let skyBlue500 = babyBlue500
        static let skyBlue600 = babyBlue600
        static let skyBlue700 = babyBlue700

        static let blue300 = babyBlue200
        static let blue400 = babyBlue300
        static let blue500 = babyBlue400
        static let blue600 = babyBlue500
        static let blue700 = babyBlue600
        static let blue800 = babyBlue700
        static let blue900 = neutral900
        static let blue50  = babyBlue50
        static let blue100 = babyBlue100

        // Semantic aliases
        static let green   = dataGreen
        static let orange  = dataCoral
        static let blue    = babyBlue400
        static let red     = blood
        static let yellow  = dataAmber
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
        static let glass: CGFloat = 24
    }

    // MARK: - Shadows

    struct Shadows {
        static func card<V: View>(_ view: V) -> some View {
            view
                .compositingGroup()
                .shadow(color: Color.black.opacity(0.05), radius: 14, x: 0, y: 6)
                .shadow(color: Color.black.opacity(0.02), radius: 3, x: 0, y: 1)
        }

        static func floating<V: View>(_ view: V) -> some View {
            view
                .compositingGroup()
                .shadow(color: Color.black.opacity(0.10), radius: 20, x: 0, y: 8)
                .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
        }

        static func subtle<V: View>(_ view: V) -> some View {
            view
                .compositingGroup()
                .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 3)
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
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 4, y: 4)
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
        static func light()     { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
        static func medium()    { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
        static func heavy()     { UIImpactFeedbackGenerator(style: .heavy).impactOccurred() }
        static func success()   { UINotificationFeedbackGenerator().notificationOccurred(.success) }
        static func selection() { UISelectionFeedbackGenerator().selectionChanged() }
    }
}

// MARK: - Backgrounds

/// v5 cream app surface. Static, solid cream.
struct CreamBackground: View {
    var body: some View {
        Theme.Colors.cream.ignoresSafeArea()
    }
}

/// Legacy alias — was a mesh background, now just cream.
struct MeshBackground: View {
    var body: some View {
        CreamBackground()
    }
}

/// Legacy alias — was a beige gradient, now just cream.
struct InsightsBackground: View {
    var body: some View {
        CreamBackground()
    }
}

/// Modal sheet background — slightly softer cream tint.
struct FrostedSheetBackground: View {
    var body: some View {
        LinearGradient(
            colors: [Theme.Colors.creamSoft, Theme.Colors.cream],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

// MARK: - Soft Glass (Tiimo-minimal)

/// Subtle frosted glass — used surgically on tab bar, FAB, contained data widgets.
/// Much lighter than v4 — barely-there material + soft white border.
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
            // Tiimo-style soft lift — two-layer drop shadow.
            // First layer creates the float; second is the contact edge.
            .compositingGroup()
            .shadow(color: Color.black.opacity(0.06), radius: 14, x: 0, y: 6)
            .shadow(color: Color.black.opacity(0.025), radius: 3, x: 0, y: 1)
    }

    private func frostedFill(shape: RoundedRectangle) -> some View {
        ZStack {
            shape.fill(.ultraThinMaterial)
            // Lower white tint (was 0.40) so more of the material gray shows
            // through — matches the D/W/M/Y toggle's look against cream.
            shape.fill(Color.white.opacity(0.25))
            if let tint {
                shape.fill(tint.opacity(0.08))
            }
        }
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func borderStroke(shape: RoundedRectangle) -> some View {
        if stroke {
            shape.stroke(Color.white.opacity(0.55), lineWidth: 1.6)
        }
    }
}

extension View {
    func glassSurface(
        radius: CGFloat = Theme.Radius.glass,
        tint: Color? = nil,
        stroke: Bool = true
    ) -> some View {
        modifier(GlassSurface(radius: radius, tint: tint, stroke: stroke))
    }
}

// MARK: - Glass Containers

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

// MARK: - Black FAB

/// Solid black floating action button. Brandon's spec: stays black.
struct GlassFAB: View {
    let action: () -> Void
    @State private var pressed: Bool = false

    var body: some View {
        Button {
            Theme.Haptics.medium()
            action()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .heavy))
                .foregroundStyle(.white)
                .frame(width: 60, height: 60)
                .background(Circle().fill(Theme.Colors.neutral900))
                .scaleEffect(pressed ? 0.92 : 1.0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { isPressing in
            withAnimation(Theme.Animation.press) { pressed = isPressing }
        }, perform: {})
        .shadow(color: Color.black.opacity(0.18), radius: 12, x: 0, y: 6)
    }
}

// MARK: - App Pages + Floating Glass Tab Bar

enum AppPage: Hashable, CaseIterable {
    case home
    case trends
    // Chat (Coach Lee) hidden for beta launch — re-enable by uncommenting
    // this case and the matching arms below, plus the `.coach` case in
    // ContentView's body switch.
    // case coach

    var label: String {
        switch self {
        case .home:   return "Home"
        case .trends: return "Trends"
        // case .coach:  return "Coach"
        }
    }

    var iconFilled: String {
        switch self {
        case .home:   return "house.fill"
        case .trends: return "chart.bar.fill"
        // case .coach:  return "message.fill"
        }
    }

    var iconOutline: String {
        switch self {
        case .home:   return "house"
        case .trends: return "chart.bar"
        // case .coach:  return "message"
        }
    }
}

/// Floating frosted-glass tab pill. Three tabs. Lives bottom-left.
/// Black FAB pinned to the right of this in the row container.
struct GlassNavPill: View {
    @Binding var selected: AppPage
    @Namespace private var ns

    var body: some View {
        HStack(spacing: 2) {
            ForEach(AppPage.allCases, id: \.self) { page in
                Button {
                    Theme.Haptics.selection()
                    withAnimation(Theme.Animation.tabSlide) { selected = page }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: selected == page ? page.iconFilled : page.iconOutline)
                            .font(.system(size: 15, weight: .semibold))
                            .symbolEffect(.bounce, value: selected == page)
                        if selected == page {
                            Text(page.label)
                                .font(Theme.Fonts.captionBold(13))
                                .transition(.opacity.combined(with: .scale(scale: 0.85)))
                        }
                    }
                    .foregroundStyle(selected == page ? Theme.Colors.espresso : Theme.Colors.espressoLight)
                    .padding(.horizontal, selected == page ? 14 : 12)
                    .padding(.vertical, 10)
                    .background(
                        ZStack {
                            if selected == page {
                                Capsule()
                                    .fill(Color.white.opacity(0.85))
                                    .matchedGeometryEffect(id: "tab_selection", in: ns)
                            }
                        }
                    )
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
        .background(navPillBackground)
        .shadow(color: Color.black.opacity(0.10), radius: 16, x: 0, y: 6)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 1)
    }

    @ViewBuilder
    private var navPillBackground: some View {
        Capsule()
            .fill(.ultraThinMaterial)
            .overlay(Capsule().fill(Color.white.opacity(0.30)))
            .overlay(Capsule().stroke(Color.white.opacity(0.55), lineWidth: 1))
    }
}

// MARK: - Mascot Avatar

/// Clean circular mascot avatar. No halo — Brandon explicitly nixed the halo idea.
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
        .shadow(color: Color.black.opacity(0.06), radius: 5, x: 0, y: 2)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { isPressing in
            withAnimation(Theme.Animation.press) { pressed = isPressing }
        }, perform: {})
    }
}

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

// MARK: - Pooply v5 — Shared Components

/// Floating delta indicator, e.g. "▲ +3 from last week".
/// Lives near the top-right of Home, floating on cream (no card).
struct TrendChip: View {
    let delta: Int
    var label: String = "from last week"

    private var isUp: Bool { delta >= 0 }
    private var color: Color {
        if delta == 0 { return Theme.Colors.espressoMid }
        return isUp ? Theme.Colors.dataGreen : Theme.Colors.dataCoral
    }
    private var symbol: String { isUp ? "+" : "" }

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: delta == 0
                  ? "minus"
                  : (isUp ? "arrow.up.right" : "arrow.down.right"))
                .font(.system(size: 10, weight: .bold))
            Text("\(symbol)\(delta) \(label)")
                .font(Theme.Fonts.captionBold(12))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(color.opacity(0.12)))
        .overlay(Capsule().stroke(color.opacity(0.18), lineWidth: 0.5))
    }
}

/// Bristol-type colored dot for the "Last 7" strip on Home.
struct BristolDot: View {
    let type: Log.PoopType?
    var size: CGFloat = 18

    private var color: Color {
        guard let type else { return Theme.Colors.neutral200 }
        switch type {
        case .smoothSausage, .crackedSausage:   return Theme.Colors.dataGreen   // 3-4
        case .softBlobs:                        return Theme.Colors.dataAmber   // 5
        case .separateHardLumps, .lumpySausage: return Theme.Colors.dataCoral   // 1-2
        case .fluffyPieces:                     return Theme.Colors.dataLoose   // 6
        case .watery:                           return Theme.Colors.dataLiquid  // 7
        }
    }

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .fill(Color.white.opacity(0.25))
                    .scaleEffect(0.45)
                    .offset(x: -size * 0.18, y: -size * 0.18)
            )
    }
}

/// Custom Pooply Green Zone leaf. Used on the Streak card as its identity icon.
struct GreenZoneLeaf: View {
    var size: CGFloat = 32
    var color: Color = Theme.Colors.dataGreen

    var body: some View {
        ZStack {
            LeafShape()
                .fill(
                    LinearGradient(
                        colors: [color, color.opacity(0.72)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            // Subtle vein line down center
            LeafVein()
                .stroke(Color.white.opacity(0.30), style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
        }
        .frame(width: size, height: size)
    }
}

private struct LeafShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        // Tilted teardrop pointing up-right
        p.move(to: CGPoint(x: w * 0.20, y: h * 0.92))
        p.addCurve(
            to: CGPoint(x: w * 0.92, y: h * 0.20),
            control1: CGPoint(x: w * 0.05, y: h * 0.55),
            control2: CGPoint(x: w * 0.40, y: h * 0.08)
        )
        p.addCurve(
            to: CGPoint(x: w * 0.20, y: h * 0.92),
            control1: CGPoint(x: w * 0.96, y: h * 0.60),
            control2: CGPoint(x: w * 0.60, y: h * 0.96)
        )
        p.closeSubpath()
        return p
    }
}

private struct LeafVein: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.width * 0.25, y: rect.height * 0.85))
        p.addQuadCurve(
            to: CGPoint(x: rect.width * 0.85, y: rect.height * 0.25),
            control: CGPoint(x: rect.width * 0.42, y: rect.height * 0.42)
        )
        return p
    }
}

// MARK: - Reusable Components (preserved API)

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

struct StatCard: View {
    let value: String
    let label: String
    let icon: String?
    let iconColor: Color
    var valueColor: Color = Theme.Colors.espresso
    var showRing: Bool = false
    var ringProgress: CGFloat = 0
    var ringColor: Color = Theme.Colors.primary

    init(value: String,
         label: String,
         icon: String? = nil,
         iconColor: Color = Theme.Colors.primary,
         valueColor: Color = Theme.Colors.espresso,
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
            .background(Theme.Colors.neutral900)
            .clipShape(Capsule())
        }
        .disabled(isLoading)
    }
}

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
            .foregroundStyle(Theme.Colors.espresso)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .glassSurface(radius: Theme.Radius.pill)
        }
    }
}

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
                .foregroundStyle(isSelected ? Theme.Colors.espresso : Theme.Colors.espressoLight)
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

struct SectionHeader: View {
    let title: String
    var action: (() -> Void)? = nil
    var actionTitle: String = "See All"
    var onDark: Bool = false

    var body: some View {
        HStack {
            Text(title)
                .font(Theme.Fonts.heading())
                .foregroundStyle(onDark ? .white : Theme.Colors.espresso)
            Spacer()
            if let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(Theme.Fonts.captionBold())
                        .foregroundStyle(Theme.Colors.espresso)
                }
            }
        }
    }
}

struct CloseButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: {
            Theme.Haptics.light()
            action()
        }) {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Theme.Colors.espresso)
                .frame(width: 36, height: 36)
                .glassSurface(radius: 18)
        }
    }
}

struct CategoryDot: View {
    let category: Log.PoopCategory
    var size: CGFloat = 10

    var color: Color {
        switch category {
        case .regular: return Theme.Colors.good
        case .hard:    return Theme.Colors.hard
        case .loose:   return Theme.Colors.loose
        }
    }

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
    }
}

// MARK: - Button Styles

struct ElevatedButtonStyle: ButtonStyle {
    var color: Color = Theme.Colors.neutral900
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
    func elevatedButtonStyle(color: Color = Theme.Colors.neutral900, height: CGFloat = 56) -> some View {
        self.buttonStyle(ElevatedButtonStyle(color: color, height: height))
    }
}

struct BouncyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(Theme.Animation.micro, value: configuration.isPressed)
    }
}

// MARK: - View Extensions

extension View {
    func screenPadding() -> some View {
        self.padding(.horizontal, Theme.Spacing.screenHorizontal)
    }

    func bouncyButton() -> some View {
        self.buttonStyle(BouncyButtonStyle())
    }

    func neumorphicShadow() -> some View {
        self
            .compositingGroup()
            .shadow(color: Color.white.opacity(0.7), radius: 6, x: -3, y: -3)
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 4, y: 4)
    }
}

// Note: cardShadow(), floatingShadow(), subtleShadow() live in Extensions.swift

// MARK: - Preview

#Preview("Design System v5") {
    ZStack {
        CreamBackground()
        ScrollView {
            VStack(spacing: 24) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Pooply")
                            .font(Theme.Fonts.title(28))
                            .foregroundStyle(Theme.Colors.espresso)
                    }
                    Spacer()
                    MascotAvatar { }
                }

                VStack(spacing: 6) {
                    Text("POOP SCORE  ·  LAST 7 DAYS")
                        .font(Theme.Fonts.label(10))
                        .tracking(1.3)
                        .foregroundStyle(Theme.Colors.espressoLight)
                    Text("84")
                        .font(Theme.Fonts.hero(120))
                        .foregroundStyle(Theme.Colors.espresso)
                }
                .padding(.vertical, 24)

                HStack(spacing: 10) {
                    ForEach(0..<7) { _ in BristolDot(type: .smoothSausage) }
                }

                HStack(spacing: 12) {
                    GreenZoneLeaf(size: 28)
                    Text("12 day Green Zone")
                        .font(Theme.Fonts.bodyBold(15))
                        .foregroundStyle(Theme.Colors.espresso)
                }

                TrendChip(delta: 3)

                HStack {
                    GlassNavPill(selected: .constant(.home))
                    Spacer()
                    GlassFAB { }
                }
                .padding(.top, 24)
            }
            .padding(Theme.Spacing.screenHorizontal)
        }
    }
}
