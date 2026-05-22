//
//  HomeView.swift
//  Pooply
//
//  Home — v4 Liquid Glass + Mesh
//  Massive PoopScore hero, glass metric trio, mascot avatar.
//  Bottom nav (Home/Insights pill) and FAB are rendered by ContentView.
//

import SwiftUI
import FirebaseAnalytics

struct HomeView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @Binding var selectedTimeframe: String
    @Binding var showProfile: Bool
    @Binding var showLogOptions: Bool

    @State private var scoreAppeared: Bool = false

    private var firstName: String {
        let name = userViewModel.user.name.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.split(separator: " ").first.map(String.init) ?? name
    }

    private var score: Int { userViewModel.averagePoopScore(for: selectedTimeframe) }

    private var scoreDelta: Int {
        let cal = Calendar.current
        let now = Date()
        let (prevStart, prevEnd): (Date, Date) = {
            switch selectedTimeframe {
            case "TODAY":
                let s = cal.startOfDay(for: now)
                let prev = cal.date(byAdding: .day, value: -1, to: s)!
                return (prev, s)
            case "MONTH":
                let s = cal.date(byAdding: .month, value: -1, to: now) ?? now
                let prev = cal.date(byAdding: .month, value: -2, to: now) ?? now
                return (prev, s)
            default:
                let s = cal.date(byAdding: .day, value: -7, to: now) ?? now
                let prev = cal.date(byAdding: .day, value: -14, to: now) ?? now
                return (prev, s)
            }
        }()

        let prevLogs = userViewModel.logHistory.filter { $0.timestamp >= prevStart && $0.timestamp < prevEnd }
        guard !prevLogs.isEmpty else { return 0 }
        let prevAvg = prevLogs.map { UserViewModel.calculatePoopScoreStatic(for: $0) }.reduce(0, +) / prevLogs.count
        return score - prevAvg
    }

    var body: some View {
        VStack(spacing: 0) {

            // MARK: - Header (greeting + mascot avatar)
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Nice to see you,")
                        .font(Theme.Fonts.body(15))
                        .foregroundStyle(Theme.Colors.textOnMesh.opacity(0.62))
                    Text(firstName)
                        .font(Theme.Fonts.title(28))
                        .foregroundStyle(Theme.Colors.textOnMesh)
                }
                Spacer()
                MascotAvatar(size: 52) { showProfile = true }
            }
            .padding(.horizontal, Theme.Spacing.screenHorizontal)
            .padding(.top, 4)

            Spacer(minLength: 8)

            // MARK: - Hero (label + inline timeframe + score + particles)
            VStack(spacing: 8) {
                Text("Poop Score")
                    .font(Theme.Fonts.subheading(17))
                    .foregroundStyle(Theme.Colors.textOnMesh.opacity(0.85))

                InlineTimeframePicker(selected: $selectedTimeframe)
                    .padding(.bottom, 18)

                ZStack {
                    PoopScoreParticles()
                        .frame(height: 220)
                        .allowsHitTesting(false)

                    ZStack(alignment: .topTrailing) {
                        Text("\(score)")
                            .font(Theme.Fonts.hero(140))
                            .foregroundStyle(Theme.Colors.textOnMesh)
                            .contentTransition(.numericText())
                            .scaleEffect(scoreAppeared ? 1.0 : 0.85)
                            .opacity(scoreAppeared ? 1.0 : 0.0)
                            .animation(.spring(response: 0.7, dampingFraction: 0.62).delay(0.1), value: scoreAppeared)

                        if scoreDelta != 0 {
                            DeltaBadge(delta: scoreDelta)
                                .offset(x: 24, y: -4)
                                .scaleEffect(scoreAppeared ? 1.0 : 0.3)
                                .opacity(scoreAppeared ? 1.0 : 0.0)
                                .animation(.spring(response: 0.5, dampingFraction: 0.55).delay(0.5), value: scoreAppeared)
                        }
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.screenHorizontal)

            Spacer(minLength: 4)

            // MARK: - Glass Metric Trio
            HStack(spacing: 10) {
                MetricGlassCard(
                    label: "HYDRATION",
                    value: percentString(userViewModel.averageHydrationPercentage(for: selectedTimeframe)),
                    sparkline: hydrationSparkline,
                    color: Theme.Colors.hydration,
                    icon: "drop.fill"
                )
                MetricGlassCard(
                    label: "BLOOD",
                    value: percentString(userViewModel.averageBloodPercentage(for: selectedTimeframe)),
                    sparkline: bloodSparkline,
                    color: Theme.Colors.blood,
                    icon: "heart.fill",
                    invertColor: true
                )
                MetricGlassCard(
                    label: "FIBER",
                    value: percentString(userViewModel.averageFiberPercentage(for: selectedTimeframe)),
                    sparkline: fiberSparkline,
                    color: Theme.Colors.fiber,
                    icon: "leaf.fill"
                )
            }
            .padding(.horizontal, Theme.Spacing.screenHorizontal)

            // MARK: - Today's Read (compact) — tighter to the metric trio
            HomeInsightCardCompact()
                .padding(.horizontal, Theme.Spacing.screenHorizontal)
                .padding(.top, 8)

            // Leave space for the nav pill + FAB row pinned to bottom
            Spacer(minLength: 110)
        }
        .onAppear {
            scoreAppeared = true
            Analytics.logEvent("home_viewed", parameters: nil)
        }
        .onChange(of: selectedTimeframe) { _, _ in
            scoreAppeared = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation { scoreAppeared = true }
            }
        }
    }

    private func percentString(_ value: CGFloat) -> String {
        "\(Int(value * 100))%"
    }

    private var hydrationSparkline: [CGFloat] {
        sparklineValues { log in log.hydrationPercentage.map { CGFloat($0) } ?? 0.5 }
    }
    private var fiberSparkline: [CGFloat] {
        sparklineValues { log in log.fiberPercentage.map { CGFloat($0) } ?? 0.4 }
    }
    private var bloodSparkline: [CGFloat] {
        sparklineValues { log in CGFloat(log.bloodPercentage) }
    }

    private func sparklineValues(_ extract: (Log) -> CGFloat) -> [CGFloat] {
        let logs = userViewModel.getLogsForTimeframe(selectedTimeframe)
            .sorted { $0.timestamp < $1.timestamp }
            .suffix(7)
        let values = logs.map(extract)
        guard !values.isEmpty else { return [0.5, 0.55, 0.5, 0.6, 0.55, 0.65, 0.6] }
        return Array(values)
    }
}

// MARK: - Delta Badge (e.g. "+4" green pill)

struct DeltaBadge: View {
    let delta: Int

    private var color: Color {
        delta >= 0 ? Theme.Colors.mint : Theme.Colors.blood
    }

    private var symbol: String {
        delta >= 0 ? "+" : ""
    }

    var body: some View {
        Text("\(symbol)\(delta)")
            .font(Theme.Fonts.bodyBold(15))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(color)
            )
            .shadow(color: color.opacity(0.35), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Inside Score Pill

struct InsideScorePill: View {
    @State private var pressed = false

    var body: some View {
        Button {
            Theme.Haptics.light()
        } label: {
            HStack(spacing: 6) {
                Text("Inside the score")
                    .font(Theme.Fonts.captionBold(13))
                Image(systemName: "arrow.right")
                    .font(.system(size: 11, weight: .bold))
            }
            .foregroundStyle(Theme.Colors.textOnGlass)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .glassSurface(radius: Theme.Radius.pill)
            .scaleEffect(pressed ? 0.94 : 1.0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { isPressing in
            withAnimation(Theme.Animation.press) { pressed = isPressing }
        }, perform: {})
    }
}

// MARK: - Particle Field around the Poop Score

struct PoopScoreParticles: View {
    @State private var particles: [Particle] = (0..<140).map { _ in Particle.random() }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                for p in particles {
                    let phase = t * p.speed + p.phaseOffset
                    let radius = p.radius + 8 * sin(phase * 0.6)
                    let angle = p.angle + CGFloat(t * p.angularSpeed)
                    let x = center.x + cos(angle) * radius
                    let y = center.y + sin(angle) * radius * 0.78
                    let alpha = 0.35 + 0.25 * sin(phase * 1.4)
                    let rect = CGRect(x: x - p.size/2, y: y - p.size/2, width: p.size, height: p.size)
                    ctx.fill(Path(ellipseIn: rect), with: .color(p.color.opacity(alpha)))
                }
            }
        }
    }

    struct Particle {
        var angle: CGFloat
        var radius: CGFloat
        var size: CGFloat
        var speed: Double
        var angularSpeed: Double
        var phaseOffset: Double
        var color: Color

        static func random() -> Particle {
            let palette: [Color] = [
                Theme.Colors.iconBlue300,
                Theme.Colors.iconBlue400,
                Theme.Colors.iconBlue200,
                Color.white,
                Color.white
            ]
            return Particle(
                angle: CGFloat.random(in: 0...(2 * .pi)),
                radius: CGFloat.random(in: 60...170),
                size: CGFloat.random(in: 1.3...3.4),
                speed: Double.random(in: 0.4...1.2),
                angularSpeed: Double.random(in: -0.12...0.12),
                phaseOffset: Double.random(in: 0...(2 * .pi)),
                color: palette.randomElement() ?? .white
            )
        }
    }
}

// MARK: - Metric Glass Card (sparkline + value)

struct MetricGlassCard: View {
    let label: String
    let value: String
    let sparkline: [CGFloat]
    let color: Color
    let icon: String
    var invertColor: Bool = false

    @State private var appeared: Bool = false

    private var displayColor: Color {
        if invertColor {
            return value == "0%" ? Theme.Colors.mint : Theme.Colors.blood
        }
        return color
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Sparkline(values: sparkline, color: displayColor)
                .frame(height: 28)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.7).delay(0.15), value: appeared)

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 1) {
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Image(systemName: icon)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(displayColor)
                    Text(value)
                        .font(Theme.Fonts.heading(20))
                        .foregroundStyle(Theme.Colors.textOnGlass)
                        .contentTransition(.numericText())
                }

                Text(label)
                    .font(Theme.Fonts.label(9))
                    .foregroundStyle(Theme.Colors.textOnGlass.opacity(0.55))
                    .tracking(0.8)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, minHeight: 135, maxHeight: 135, alignment: .topLeading)
        .glassSurface(radius: 18)
        .onAppear { appeared = true }
    }
}

// MARK: - Sparkline

struct Sparkline: View {
    let values: [CGFloat]
    let color: Color

    var body: some View {
        GeometryReader { geo in
            let path = smoothPath(in: geo.size)
            ZStack {
                path
                    .addingLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
                    .addingLine(to: CGPoint(x: 0, y: geo.size.height))
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.18), color.opacity(0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                path
                    .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

                if let last = values.last {
                    let x = geo.size.width
                    let y = yPosition(for: last, height: geo.size.height)
                    Circle()
                        .fill(color)
                        .frame(width: 6, height: 6)
                        .position(x: x - 3, y: y)
                }
            }
        }
    }

    private func smoothPath(in size: CGSize) -> Path {
        guard values.count > 1 else { return Path() }
        let stepX = size.width / CGFloat(values.count - 1)
        let points: [CGPoint] = values.enumerated().map { i, v in
            CGPoint(x: CGFloat(i) * stepX, y: yPosition(for: v, height: size.height))
        }

        var path = Path()
        path.move(to: points[0])

        for i in 1..<points.count {
            let prev = points[i - 1]
            let curr = points[i]
            let mid = CGPoint(x: (prev.x + curr.x) / 2, y: (prev.y + curr.y) / 2)
            if i == 1 {
                path.addLine(to: mid)
            } else {
                path.addQuadCurve(to: mid, control: prev)
            }
            if i == points.count - 1 {
                path.addQuadCurve(to: curr, control: prev)
            }
        }
        return path
    }

    private func yPosition(for value: CGFloat, height: CGFloat) -> CGFloat {
        let minV = values.min() ?? 0
        let maxV = values.max() ?? 1
        let range = max(maxV - minV, 0.0001)
        let normalized = (value - minV) / range
        return height - (normalized * (height - 4)) - 2
    }
}

extension Path {
    func addingLine(to point: CGPoint) -> Path {
        var copy = self
        copy.addLine(to: point)
        return copy
    }
}

// MARK: - Home Insight Card (today's read) — compact, single-row

struct HomeInsightCardCompact: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @State private var showInsightsModal: Bool = false
    @State private var pressed: Bool = false

    private var insight: String {
        let baseline = userViewModel.calculatePersonalBaseline()
        let avg = baseline.averagePoopScore
        let hydration = baseline.averageHydration

        if hydration < 0.5 {
            return "Your hydration is trending low. Try drinking more water."
        }
        if avg < 60 {
            return "Your gut needs a tune-up. Add fiber and water."
        }
        if avg >= 80 {
            return "Your gut is dialed. Keep it up."
        }
        return "You're trending right where you want to be."
    }

    var body: some View {
        Button {
            Theme.Haptics.light()
            showInsightsModal = true
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("TODAY'S READ")
                        .font(Theme.Fonts.label(9))
                        .foregroundStyle(Theme.Colors.textOnGlass.opacity(0.55))
                        .tracking(1.2)

                    Text(insight)
                        .font(.custom("PlusJakartaSans-SemiBold", size: 14))
                        .foregroundStyle(Theme.Colors.textOnGlass)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 4)
                ZStack {
                    Circle().fill(Theme.Colors.neutral900).frame(width: 32, height: 32)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                }
                .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .glassSurface(radius: 20)
            .scaleEffect(pressed ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { isPressing in
            withAnimation(Theme.Animation.press) { pressed = isPressing }
        }, perform: {})
        .sheet(isPresented: $showInsightsModal) {
            TodaysReadModal(headline: insight)
                .environmentObject(userViewModel)
                .presentationBackground(.clear)
                .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Today's Read Modal (full AI insights, frosted sheet)

struct TodaysReadModal: View {
    let headline: String
    @EnvironmentObject var userViewModel: UserViewModel
    @Environment(\.dismiss) private var dismiss

    private var insights: [UserViewModel.AdvancedInsight] {
        userViewModel.generateAdvancedInsights(for: "WEEK")
    }

    var body: some View {
        ZStack {
            FrostedSheetBackground()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("TODAY'S READ")
                            .font(Theme.Fonts.label(10))
                            .foregroundStyle(Theme.Colors.textOnGlass.opacity(0.55))
                            .tracking(1.5)

                        Text(headline)
                            .font(Theme.Fonts.title(26))
                            .foregroundStyle(Theme.Colors.textOnGlass)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, Theme.Spacing.md)

                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(insights.prefix(6)) { insight in
                            AdvancedInsightCardGlass(insight: insight)
                        }
                    }

                    Spacer().frame(height: Theme.Spacing.xxl)
                }
                .padding(.horizontal, Theme.Spacing.screenHorizontal)
                .padding(.top, Theme.Spacing.lg)
            }
        }
    }
}

// MARK: - Inline Timeframe Picker (text-only, no pill)

struct InlineTimeframePicker: View {
    @Binding var selected: String
    private let options = [("Today", "TODAY"), ("Week", "WEEK"), ("Month", "MONTH")]

    var body: some View {
        HStack(spacing: 18) {
            ForEach(Array(options.enumerated()), id: \.element.1) { index, opt in
                let (label, value) = opt
                Button {
                    Theme.Haptics.selection()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        selected = value
                    }
                } label: {
                    Text(label)
                        .font(selected == value
                              ? Theme.Fonts.captionBold(15)
                              : Theme.Fonts.caption(15))
                        .foregroundStyle(selected == value
                                         ? Theme.Colors.textOnMesh
                                         : Theme.Colors.textOnMesh.opacity(0.38))
                }
                .buttonStyle(.plain)

                if index < options.count - 1 {
                    Circle()
                        .fill(Theme.Colors.textOnMesh.opacity(0.3))
                        .frame(width: 3, height: 3)
                }
            }
        }
    }
}

// MARK: - Legacy alias

typealias HomeTimeframePicker = InlineTimeframePicker

// MARK: - Preview

#Preview {
    ZStack {
        MeshBackground()
        HomeView(
            selectedTimeframe: .constant("WEEK"),
            showProfile: .constant(false),
            showLogOptions: .constant(false)
        )
        .environmentObject(
            UserViewModel(
                user: User(name: "Brandon", age: 25, weight: 160, gender: "male"),
                withDummyData: true
            )
        )
    }
}
