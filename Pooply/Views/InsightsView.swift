//
//  InsightsView.swift
//  Pooply
//
//  Insights — v4 Liquid Glass + Mesh
//  Score trend (line), Quality bars, streaks, calendar — all glass over the mesh.
//

import SwiftUI
import Charts

struct InsightsView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var subscriptionService: SubscriptionService
    @Binding var showProfile: Bool
    // Each graph owns its own timeframe so changing one doesn't move the other.
    @State private var scoreTrendTimeframe = "WEEK"
    @State private var qualityTimeframe = "WEEK"
    @State private var statsTimeframe = "WEEK"
    @State private var selectedMonth: Date = .currentMonth
    @State private var selectedDate: Date = .now

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {

                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Your gut")
                            .font(Theme.Fonts.body(15))
                            .foregroundStyle(Theme.Colors.textOnMesh.opacity(0.62))
                        Text("Insights")
                            .font(Theme.Fonts.title(28))
                            .foregroundStyle(Theme.Colors.textOnMesh)
                    }
                    Spacer()
                    MascotAvatar(size: 52) { showProfile = true }
                }
                .padding(.horizontal, Theme.Spacing.screenHorizontal)
                .padding(.top, 4)

                // Score Trend — line chart of Poop Score over time
                ScoreTrendCardInsights(selectedTimeframe: $scoreTrendTimeframe)
                    .padding(.horizontal, Theme.Spacing.screenHorizontal)

                // Quality Chart (segmented bars)
                QualityChartGlass(selectedTimeframe: $qualityTimeframe)
                    .padding(.horizontal, Theme.Spacing.screenHorizontal)

                // Floating stat numbers — no card container
                PatternStatsFloating(timeframe: statsTimeframe)
                    .padding(.horizontal, Theme.Spacing.screenHorizontal)

                // Streaks — red/orange mesh gradient
                StreaksMeshCard()
                    .padding(.horizontal, Theme.Spacing.screenHorizontal)

                InsightsDottedDivider()
                    .padding(.horizontal, Theme.Spacing.screenHorizontal)

                CalendarFloating(
                    selectedMonth: $selectedMonth,
                    selectedDate: $selectedDate
                )
                .padding(.horizontal, Theme.Spacing.screenHorizontal)

                InsightsDottedDivider()
                    .padding(.horizontal, Theme.Spacing.screenHorizontal)

                // App is free — always show smart insights, no Pro upsell.
                // Smart insights derive from all-time data, not a picker.
                SmartInsightsGlass(timeframe: "WEEK")
                    .padding(.horizontal, Theme.Spacing.screenHorizontal)

                Spacer().frame(height: 120)
            }
            .padding(.top, 8)
        }
    }
}

// MARK: - Score Trend Card (line chart of Poop Score over time)

private struct ScoreTrendCardInsights: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @Binding var selectedTimeframe: String

    private var chartTitle: String {
        switch selectedTimeframe {
        case "TODAY": return "Today"
        case "MONTH": return "Last 30 days"
        default: return "Last 7 days"
        }
    }

    private var values: [Double] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let dayCount: Int = {
            switch selectedTimeframe {
            case "TODAY": return 1
            case "MONTH": return 30
            default: return 7
            }
        }()

        var out: [Double] = []
        for offset in (1 - dayCount)...0 {
            guard let day = cal.date(byAdding: .day, value: offset, to: today) else { continue }
            let logs = userViewModel.logHistory.filter { cal.isDate($0.timestamp, inSameDayAs: day) }
            if logs.isEmpty {
                out.append(0)
            } else {
                let avg = logs.map { UserViewModel.calculatePoopScoreStatic(for: $0) }.reduce(0, +) / logs.count
                out.append(Double(avg))
            }
        }
        return out
    }

    private var hasData: Bool { values.contains(where: { $0 > 0 }) }

    private var avgScore: Int {
        let scoredDays = values.filter { $0 > 0 }
        guard !scoredDays.isEmpty else { return 0 }
        return Int(scoredDays.reduce(0, +) / Double(scoredDays.count))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Poop Score")
                        .font(Theme.Fonts.subheading(18))
                        .foregroundStyle(Theme.Colors.textOnGlass)
                    Text(chartTitle)
                        .font(Theme.Fonts.caption(12))
                        .foregroundStyle(Theme.Colors.textOnGlass.opacity(0.6))
                }
                Spacer()
                CompactTimeframePicker(selected: $selectedTimeframe)
            }

            if hasData {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(avgScore)")
                        .font(Theme.Fonts.hero(40))
                        .foregroundStyle(Theme.Colors.textOnGlass)
                        .contentTransition(.numericText())
                    Text("avg")
                        .font(Theme.Fonts.captionBold(12))
                        .foregroundStyle(Theme.Colors.textOnGlass.opacity(0.55))
                }
                .padding(.top, 2)
            }

            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .trailing, spacing: 0) {
                    Text("100").yAxisStyle()
                    Spacer(minLength: 0)
                    Text("50").yAxisStyle()
                    Spacer(minLength: 0)
                    Text("0").yAxisStyle()
                }
                .frame(width: 22)
                .frame(height: 180)

                ScoreTrendChart(values: values)
                    .frame(height: 180)
            }
        }
        .padding(18)
        .glassSurface(radius: 24)
    }
}

private extension Text {
    func yAxisStyle() -> some View {
        self
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(Theme.Colors.textOnGlass.opacity(0.45))
    }
}

// MARK: - Score Trend Chart (Catmull-Rom, color-banded, shaded fill)

struct ScoreTrendChart: View {
    let values: [Double]

    private var avgColor: Color {
        guard !values.isEmpty else { return Theme.Colors.good }
        let scoredDays = values.filter { $0 > 0 }
        guard !scoredDays.isEmpty else { return Theme.Colors.good }
        let avg = scoredDays.reduce(0, +) / Double(scoredDays.count)
        return bandColor(for: avg)
    }

    private func bandColor(for value: Double) -> Color {
        if value < 40 { return Theme.Colors.loose }
        if value < 70 { return Theme.Colors.hard }
        return Theme.Colors.good
    }

    private var hasData: Bool { values.contains(where: { $0 > 0 }) }

    var body: some View {
        GeometryReader { geo in
            if hasData {
                let path = smoothPath(in: geo.size)
                ZStack {
                    path
                        .addingLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
                        .addingLine(to: CGPoint(x: 0, y: geo.size.height))
                        .fill(
                            LinearGradient(
                                colors: [
                                    avgColor.opacity(0.42),
                                    avgColor.opacity(0.16),
                                    avgColor.opacity(0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    path.stroke(
                        LinearGradient(
                            colors: values.map { bandColor(for: $0) },
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                    )

                    if let last = values.last {
                        let y = yPosition(for: last, height: geo.size.height)
                        Circle()
                            .fill(bandColor(for: last))
                            .frame(width: 7, height: 7)
                            .position(x: geo.size.width - 4, y: y)
                    }
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

    private func yPosition(for value: Double, height: CGFloat) -> CGFloat {
        let normalized = CGFloat(max(0, min(value, 100)) / 100.0)
        return height - (normalized * (height - 10)) - 5
    }
}

// MARK: - Quality Chart (Glass)

private struct QualityChartGlass: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @Binding var selectedTimeframe: String

    private struct ChartEntry: Identifiable, Equatable {
        let id = UUID()
        let day: Date
        let category: Cat
        let count: Int
    }

    private enum Cat: String {
        case regular, hard, loose
        var color: Color {
            switch self {
            case .regular: return Theme.Colors.good
            case .hard: return Theme.Colors.hard
            case .loose: return Theme.Colors.loose
            }
        }
    }

    private var chartData: [ChartEntry] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let (start, days) = dateRange(for: selectedTimeframe, calendar: cal, today: today)
        let filtered = userViewModel.getLogsForTimeframe(selectedTimeframe).filter { $0.timestamp >= start }
        let grouped = Dictionary(grouping: filtered) { cal.startOfDay(for: $0.timestamp) }

        return days.flatMap { day -> [ChartEntry] in
            let logs = grouped[day] ?? []
            let regular = logs.filter { $0.poopScore == .regular }.count
            let hard = logs.filter { $0.poopScore == .hard }.count
            let loose = logs.filter { $0.poopScore == .loose }.count
            return [
                ChartEntry(day: day, category: .regular, count: regular),
                ChartEntry(day: day, category: .hard, count: hard),
                ChartEntry(day: day, category: .loose, count: loose)
            ]
        }
    }

    private func dateRange(for tf: String, calendar: Calendar, today: Date) -> (start: Date, days: [Date]) {
        switch tf {
        case "TODAY":
            return (today, [today])
        case "MONTH":
            let start = calendar.date(byAdding: .day, value: -29, to: today)!
            let days = (0..<30).compactMap { calendar.date(byAdding: .day, value: -29 + $0, to: today) }
            return (start, days)
        default:
            let start = calendar.date(byAdding: .day, value: -6, to: today)!
            let days = (0..<7).compactMap { calendar.date(byAdding: .day, value: -6 + $0, to: today) }
            return (start, days)
        }
    }

    private var yMax: Int {
        max((chartData.map(\.count).max() ?? 1) + 1, 4)
    }

    private var chartTitle: String {
        switch selectedTimeframe {
        case "TODAY": return "Today"
        case "MONTH": return "Last 30 days"
        default: return "Last 7 days"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Quality")
                        .font(Theme.Fonts.subheading(18))
                        .foregroundStyle(Theme.Colors.textOnGlass)
                    Text(chartTitle)
                        .font(Theme.Fonts.caption(12))
                        .foregroundStyle(Theme.Colors.textOnGlass.opacity(0.6))
                }
                Spacer()
                CompactTimeframePicker(selected: $selectedTimeframe)
            }

            Chart {
                ForEach(chartData) { entry in
                    BarMark(
                        x: .value("Day", entry.day, unit: .day),
                        y: .value("Count", entry.count)
                    )
                    .foregroundStyle(entry.category.color.gradient)
                    .cornerRadius(5)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: Array(0...yMax)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.white.opacity(0.25))
                    AxisValueLabel {
                        if let v = value.as(Int.self) {
                            Text("\(v)")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(Theme.Colors.textOnGlass.opacity(0.6))
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: selectedTimeframe == "MONTH" ? 7 : 1)) { value in
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(formatXAxis(date))
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(Theme.Colors.textOnGlass.opacity(0.6))
                        }
                    }
                }
            }
            .chartYScale(domain: 0...yMax)
            .frame(height: 200)
            .animation(Theme.Animation.spring, value: chartData)

            HStack(spacing: Theme.Spacing.lg) {
                LegendDot(color: Theme.Colors.good, label: "Good")
                LegendDot(color: Theme.Colors.hard, label: "Hard")
                LegendDot(color: Theme.Colors.loose, label: "Loose")
            }
        }
        .padding(18)
        .glassSurface(radius: 24)
    }

    private func formatXAxis(_ date: Date) -> String {
        let f = DateFormatter()
        switch selectedTimeframe {
        case "TODAY": f.dateFormat = "h a"
        case "MONTH": f.dateFormat = "M/d"
        default: f.dateFormat = "E"
        }
        return f.string(from: date)
    }
}

// MARK: - Compact Timeframe Picker

private struct CompactTimeframePicker: View {
    @Binding var selected: String
    @Namespace private var ns
    private let opts = [("D", "TODAY"), ("W", "WEEK"), ("M", "MONTH")]

    var body: some View {
        HStack(spacing: 2) {
            ForEach(opts, id: \.1) { label, value in
                Button {
                    Theme.Haptics.selection()
                    withAnimation(Theme.Animation.tabSlide) {
                        selected = value
                    }
                } label: {
                    Text(label)
                        .font(Theme.Fonts.label(11))
                        .foregroundStyle(selected == value ? .white : Color.white.opacity(0.45))
                        .frame(width: 30, height: 26)
                        .background {
                            if selected == value {
                                Capsule()
                                    .fill(Color.white.opacity(0.18))
                                    .matchedGeometryEffect(id: "compact_pick", in: ns)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(Capsule().fill(Theme.Colors.neutral900))
    }
}

private struct LegendDot: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label)
                .font(Theme.Fonts.caption(12))
                .foregroundStyle(Theme.Colors.textOnGlass.opacity(0.75))
        }
    }
}

// MARK: - Insights Dotted Divider

private struct InsightsDottedDivider: View {
    var body: some View {
        GeometryReader { geo in
            let dotCount = Int(geo.size.width / 9)
            HStack(spacing: 6) {
                ForEach(0..<dotCount, id: \.self) { _ in
                    Circle()
                        .fill(Theme.Colors.textOnGlass.opacity(0.25))
                        .frame(width: 3, height: 3)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .frame(height: 3)
    }
}

// MARK: - Pattern Stats Floating (no card)

private struct PatternStatsFloating: View {
    @EnvironmentObject var userViewModel: UserViewModel
    let timeframe: String

    var body: some View {
        let stats = userViewModel.getPatternStats(for: timeframe)
        HStack(spacing: 8) {
            ForEach(stats) { stat in
                VStack(spacing: 4) {
                    Text(stat.value)
                        .font(Theme.Fonts.hero(34))
                        .foregroundStyle(Theme.Colors.textOnGlass)
                        .contentTransition(.numericText())
                    Text(stat.label.uppercased())
                        .font(Theme.Fonts.label(10))
                        .foregroundStyle(Theme.Colors.textOnGlass.opacity(0.5))
                        .tracking(1)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - Streaks Mesh Card (red + orange fire gradient)

private struct StreaksMeshCard: View {
    @EnvironmentObject var userViewModel: UserViewModel

    private var meshPoints: [SIMD2<Float>] {
        [
            SIMD2(0.0, 0.0), SIMD2(0.5, 0.0), SIMD2(1.0, 0.0),
            SIMD2(0.0, 0.5), SIMD2(0.5, 0.5), SIMD2(1.0, 0.5),
            SIMD2(0.0, 1.0), SIMD2(0.5, 1.0), SIMD2(1.0, 1.0)
        ]
    }

    private var meshColors: [Color] {
        [
            Color(hex: "#E84545"), Color(hex: "#F26B5C"), Color(hex: "#F58A33"),
            Color(hex: "#D63452"), Color(hex: "#F26B5C"), Color(hex: "#FFAB5C"),
            Color(hex: "#B82847"), Color(hex: "#E84545"), Color(hex: "#F58A33")
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.white)
                Text("Streaks")
                    .font(Theme.Fonts.title(28))
                    .foregroundStyle(.white)
            }

            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(userViewModel.regularStreak)")
                            .font(Theme.Fonts.hero(56))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())
                        Text("days")
                            .font(Theme.Fonts.bodyBold(14))
                            .foregroundStyle(.white.opacity(0.75))
                    }
                    Text("Current Streak")
                        .font(Theme.Fonts.captionBold(12))
                        .foregroundStyle(.white.opacity(0.75))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Rectangle()
                    .fill(Color.white.opacity(0.25))
                    .frame(width: 1, height: 56)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(userViewModel.longestRegularStreak)")
                            .font(Theme.Fonts.hero(56))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())
                        Text("days")
                            .font(Theme.Fonts.bodyBold(14))
                            .foregroundStyle(.white.opacity(0.75))
                    }
                    Text("Longest Streak")
                        .font(Theme.Fonts.captionBold(12))
                        .foregroundStyle(.white.opacity(0.75))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 16)
            }
        }
        .padding(20)
        .background(
            MeshGradient(width: 3, height: 3, points: meshPoints, colors: meshColors)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        )
        .shadow(color: Color(hex: "#E84545").opacity(0.25), radius: 16, x: 0, y: 8)
    }
}

// MARK: - Calendar Floating (no card wrapper)

private struct CalendarFloating: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @Binding var selectedMonth: Date
    @Binding var selectedDate: Date
    @State private var dayLogsModalDate: Date?

    private var monthTitle: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: selectedMonth)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Button {
                    Theme.Haptics.light()
                    if let m = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) {
                        withAnimation(Theme.Animation.spring) { selectedMonth = m }
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Theme.Colors.neutral900))
                }

                Spacer()
                Text(monthTitle)
                    .font(Theme.Fonts.subheading(18))
                    .foregroundStyle(Theme.Colors.textOnGlass)
                Spacer()

                Button {
                    Theme.Haptics.light()
                    if let m = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) {
                        withAnimation(Theme.Animation.spring) { selectedMonth = m }
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Theme.Colors.neutral900))
                }
            }

            HStack(spacing: 0) {
                ForEach(["S","M","T","W","T","F","S"], id: \.self) { label in
                    Text(label)
                        .font(Theme.Fonts.label(10))
                        .foregroundStyle(Theme.Colors.textOnGlass.opacity(0.5))
                        .frame(maxWidth: .infinity)
                }
            }

            let actualDays = monthDays(for: selectedMonth)
            // spacing 0 so connected pills touch edge-to-edge; per-cell padding
            // creates the visual gap on unconnected sides.
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 6) {
                ForEach(Array(actualDays.enumerated()), id: \.element.id) { idx, day in
                    let cat = dominantCategory(for: day.date)
                    let leftConnected = !day.ignored
                        && cat != nil
                        && idx > 0
                        && !actualDays[idx - 1].ignored
                        && dominantCategory(for: actualDays[idx - 1].date) == cat
                    let rightConnected = !day.ignored
                        && cat != nil
                        && idx < actualDays.count - 1
                        && !actualDays[idx + 1].ignored
                        && dominantCategory(for: actualDays[idx + 1].date) == cat

                    CalendarDayDot(
                        date: day.date,
                        isIgnored: day.ignored,
                        category: cat,
                        hasLogs: !logsFor(day.date).isEmpty,
                        leftConnected: leftConnected,
                        rightConnected: rightConnected,
                        onTap: {
                            let logs = logsFor(day.date)
                            guard !logs.isEmpty else { return }
                            Theme.Haptics.light()
                            selectedDate = day.date
                            dayLogsModalDate = day.date
                        }
                    )
                }
            }
        }
        .sheet(item: Binding(
            get: { dayLogsModalDate.map { DayLogsIdentifier(date: $0) } },
            set: { dayLogsModalDate = $0?.date }
        )) { ident in
            DayLogsModal(date: ident.date, logs: logsFor(ident.date))
                .presentationBackground(.clear)
                .presentationDragIndicator(.visible)
        }
    }

    private func logsFor(_ date: Date) -> [Log] {
        let cal = Calendar.current
        return userViewModel.logHistory
            .filter { cal.isDate($0.timestamp, inSameDayAs: date) }
            .sorted { $0.timestamp > $1.timestamp }
    }

    private func scoreFor(_ date: Date) -> Int? {
        let cal = Calendar.current
        let logs = userViewModel.logHistory.filter { cal.isDate($0.timestamp, inSameDayAs: date) }
        guard !logs.isEmpty else { return nil }
        return logs.map { UserViewModel.calculatePoopScoreStatic(for: $0) }.reduce(0, +) / logs.count
    }

    // Dominant category for a given day — mode of that day's logs.
    // Used to drive the color of the calendar pill.
    private func dominantCategory(for date: Date) -> Log.PoopCategory? {
        let logs = logsFor(date)
        guard !logs.isEmpty else { return nil }
        var counts: [Log.PoopCategory: Int] = [:]
        for log in logs {
            counts[log.poopScore, default: 0] += 1
        }
        return counts.max(by: { $0.value < $1.value })?.key
    }

    private func monthDays(for month: Date) -> [TempDay] {
        var days: [TempDay] = []
        let cal = Calendar.current
        let f = DateFormatter()
        f.dateFormat = "dd"

        guard let range = cal.range(of: .day, in: .month, for: month)?.compactMap({
            value -> Date? in cal.date(byAdding: .day, value: value - 1, to: month)
        }) else { return days }

        let firstWeekDay = cal.component(.weekday, from: range.first!)
        for index in Array(0..<firstWeekDay - 1).reversed() {
            guard let d = cal.date(byAdding: .day, value: -index - 1, to: range.first!) else { return days }
            days.append(.init(shortSymbol: f.string(from: d), date: d, ignored: true))
        }
        for d in range {
            days.append(.init(shortSymbol: f.string(from: d), date: d))
        }
        let lastWeekDay = 7 - cal.component(.weekday, from: range.last!)
        if lastWeekDay > 0 {
            for index in 0..<lastWeekDay {
                guard let d = cal.date(byAdding: .day, value: index + 1, to: range.last!) else { return days }
                days.append(.init(shortSymbol: f.string(from: d), date: d, ignored: true))
            }
        }
        return days
    }
}

private struct CalendarDayDot: View {
    let date: Date
    let isIgnored: Bool
    let category: Log.PoopCategory?
    var hasLogs: Bool = false
    var leftConnected: Bool = false
    var rightConnected: Bool = false
    var onTap: (() -> Void)? = nil

    private var dayNum: String {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f.string(from: date)
    }

    private var pillColor: Color {
        guard let category else { return Color.white.opacity(0.10) }
        switch category {
        case .regular: return Theme.Colors.good
        case .hard:    return Theme.Colors.hard
        case .loose:   return Theme.Colors.loose
        }
    }

    // Pill corner radii adapt to streak connection: flat where it joins a
    // neighbor, rounded where the streak ends. A single-day "streak" is a
    // fully rounded pill.
    private var corners: (tl: CGFloat, tr: CGFloat, bl: CGFloat, br: CGFloat) {
        let r: CGFloat = 14
        let leadingR: CGFloat = leftConnected ? 0 : r
        let trailingR: CGFloat = rightConnected ? 0 : r
        return (leadingR, trailingR, leadingR, trailingR)
    }

    var body: some View {
        Button {
            onTap?()
        } label: {
            ZStack {
                // Pill background — extends to cell edge on connected sides
                // so adjacent connected cells touch with no visual gap.
                UnevenRoundedRectangle(
                    topLeadingRadius: corners.tl,
                    bottomLeadingRadius: corners.bl,
                    bottomTrailingRadius: corners.br,
                    topTrailingRadius: corners.tr,
                    style: .continuous
                )
                .fill(pillColor)
                .frame(height: 32)
                .padding(.leading, leftConnected ? 0 : 4)
                .padding(.trailing, rightConnected ? 0 : 4)
                .opacity(isIgnored ? 0.25 : (category == nil ? 0.5 : 0.92))

                Text(dayNum)
                    .font(Theme.Fonts.captionBold(12))
                    .foregroundStyle(category != nil ? .white : Theme.Colors.textOnGlass.opacity(0.55))
                    .opacity(isIgnored ? 0.3 : 1.0)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!hasLogs || isIgnored)
    }
}

// MARK: - Day Logs Modal

private struct DayLogsIdentifier: Identifiable {
    let date: Date
    var id: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}

private struct DayLogsModal: View {
    let date: Date
    let logs: [Log]
    @Environment(\.dismiss) private var dismiss

    private var dateTitle: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE"
        let weekday = f.string(from: date)
        f.dateFormat = "MMM d"
        return "\(weekday), \(f.string(from: date))"
    }

    var body: some View {
        ZStack {
            FrostedSheetBackground()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("LOGS")
                            .font(Theme.Fonts.label(10))
                            .foregroundStyle(Theme.Colors.textOnGlass.opacity(0.55))
                            .tracking(1.5)
                        Text(dateTitle)
                            .font(Theme.Fonts.title(26))
                            .foregroundStyle(Theme.Colors.textOnGlass)
                    }
                    .padding(.top, Theme.Spacing.md)

                    VStack(spacing: 10) {
                        ForEach(logs) { log in
                            LogCard(log: log)
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

// MARK: - Smart Insights (Glass)

private struct SmartInsightsGlass: View {
    @EnvironmentObject var userViewModel: UserViewModel
    let timeframe: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Smart Insights")
                .font(Theme.Fonts.subheading(18))
                .foregroundStyle(Theme.Colors.textOnMesh)
                .padding(.horizontal, 4)

            let insights = userViewModel.generateAdvancedInsights(for: timeframe)
            ForEach(insights.prefix(5)) { insight in
                AdvancedInsightCardGlass(insight: insight)
            }
        }
    }
}

struct AdvancedInsightCardGlass: View {
    let insight: UserViewModel.AdvancedInsight

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle().fill(insight.iconColor.opacity(0.18))
                    Image(systemName: insight.icon)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(insight.iconColor)
                }
                .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(insight.title)
                            .font(Theme.Fonts.bodyBold(15))
                            .foregroundStyle(Theme.Colors.textOnGlass)
                        Spacer()
                        if let metric = insight.metric {
                            Text(metric)
                                .font(Theme.Fonts.captionBold(12))
                                .foregroundStyle(insight.iconColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(insight.iconColor.opacity(0.15)))
                        }
                    }
                    Text(insight.description)
                        .font(Theme.Fonts.caption(13))
                        .foregroundStyle(Theme.Colors.textOnGlass.opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if let actionable = insight.actionable {
                HStack(spacing: 6) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.Colors.amber)
                    Text(actionable)
                        .font(Theme.Fonts.caption(12))
                        .foregroundStyle(Theme.Colors.textOnGlass.opacity(0.7))
                        .italic()
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassSurface(radius: 18)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        MeshBackground()
        InsightsView(showProfile: .constant(false))
            .environmentObject(
                UserViewModel(
                    user: User(name: "Brandon", age: 25, weight: 160, gender: "male"),
                    withDummyData: true
                )
            )
            .environmentObject(SubscriptionService.shared)
    }
}
