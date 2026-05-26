//
//  InsightsView.swift
//  Pooply
//
//  Trends — v5 Tiimo-minimal.
//  Lives on the "Trends" tab. D/W/M/Y toggle, polished line chart,
//  bidirectional quality chart, regularity 24h clock, frequency bars,
//  calendar with Green Zone day coloring, smart insights.
//
//  Struct name `InsightsView` retained for compat with ContentView wiring.
//

import SwiftUI
import Charts

struct InsightsView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var subscriptionService: SubscriptionService
    @Binding var showProfile: Bool

    @State private var timeframe: String = "WEEK"

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                ScoreLineChartCard(timeframe: timeframe)
                    .padding(.horizontal, Theme.Spacing.screenHorizontal)

                QualityBidirectionalCard(timeframe: timeframe)
                    .padding(.horizontal, Theme.Spacing.screenHorizontal)

                RegularityClockCard()
                    .padding(.horizontal, Theme.Spacing.screenHorizontal)

                FrequencyBarCard(timeframe: timeframe)
                    .padding(.horizontal, Theme.Spacing.screenHorizontal)

                SmartInsightsSection(timeframe: timeframe)
                    .padding(.horizontal, Theme.Spacing.screenHorizontal)

                Spacer().frame(height: 120)
            }
            .padding(.top, 12)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    Text("Trends")
                        .font(Theme.Fonts.title(28))
                        .foregroundStyle(Theme.Colors.espresso)
                    Spacer()
                    MascotAvatar(size: 52) { showProfile = true }
                }
                TimeframeToggle(selected: $timeframe)
            }
            .padding(.horizontal, Theme.Spacing.screenHorizontal)
            .padding(.top, 8)
            .padding(.bottom, 10)
            .background(
                Theme.Colors.cream
                    .ignoresSafeArea(edges: .top)
            )
        }
    }
}

// MARK: - Timeframe Toggle (Week / Month / Year) — segmented pill

private struct TimeframeToggle: View {
    @Binding var selected: String
    @Namespace private var ns
    private let opts: [(String, String)] = [("Week", "WEEK"), ("Month", "MONTH"), ("Year", "YEAR")]

    var body: some View {
        HStack(spacing: 2) {
            ForEach(opts, id: \.1) { label, value in
                Button {
                    Theme.Haptics.selection()
                    withAnimation(Theme.Animation.tabSlide) { selected = value }
                } label: {
                    Text(label)
                        .font(Theme.Fonts.captionBold(13))
                        .foregroundStyle(selected == value ? Theme.Colors.espresso : Theme.Colors.espressoLight)
                        .frame(maxWidth: .infinity, minHeight: 28)
                        .background(
                            ZStack {
                                if selected == value {
                                    Capsule()
                                        .fill(Color.white.opacity(0.85))
                                        .matchedGeometryEffect(id: "tf_pill", in: ns)
                                }
                            }
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(Capsule().fill(Color.white.opacity(0.25)))
                .overlay(Capsule().stroke(Color.white.opacity(0.55), lineWidth: 1))
        )
    }
}

// MARK: - Score Line Chart Card

private struct ScoreLineChartCard: View {
    @EnvironmentObject var userViewModel: UserViewModel
    let timeframe: String

    private var dayCount: Int {
        switch timeframe {
        case "WEEK":  return 7
        case "MONTH": return 30
        case "YEAR":  return 365
        default: return 7
        }
    }

    private var values: [Double] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<dayCount).reversed().map { offset -> Double in
            guard let day = cal.date(byAdding: .day, value: -offset, to: today) else { return 0 }
            let logs = userViewModel.logHistory.filter { cal.isDate($0.timestamp, inSameDayAs: day) }
            guard !logs.isEmpty else { return 0 }
            let avg = logs.map { UserViewModel.calculatePoopScoreStatic(for: $0) }.reduce(0, +) / logs.count
            return Double(avg)
        }
    }

    private var hasData: Bool { values.contains(where: { $0 > 0 }) }

    private var avgScore: Int {
        let scored = values.filter { $0 > 0 }
        guard !scored.isEmpty else { return 0 }
        return Int(scored.reduce(0, +) / Double(scored.count))
    }

    private var bandColor: Color {
        let avg = Double(avgScore)
        if avg < 40 { return Theme.Colors.dataCoral }
        if avg < 70 { return Theme.Colors.dataAmber }
        return Theme.Colors.dataGreen
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Poop Score")
                        .font(Theme.Fonts.subheading(18))
                        .foregroundStyle(Theme.Colors.espresso)
                    Text(timeframeLabel())
                        .font(Theme.Fonts.caption(12))
                        .foregroundStyle(Theme.Colors.espressoLight)
                }
                Spacer()
                if hasData {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(avgScore)")
                            .font(Theme.Fonts.hero(36))
                            .foregroundStyle(Theme.Colors.espresso)
                            .contentTransition(.numericText())
                        Text("avg")
                            .font(Theme.Fonts.captionBold(11))
                            .foregroundStyle(Theme.Colors.espressoLight)
                    }
                }
            }

            ZStack(alignment: .topLeading) {
                yAxisLabels
                if hasData {
                    LineAreaChart(values: values, color: bandColor)
                        .frame(height: 150)
                        .padding(.leading, 30)
                } else {
                    Text("No data yet")
                        .font(Theme.Fonts.caption(13))
                        .foregroundStyle(Theme.Colors.espressoLight)
                        .frame(height: 150)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.leading, 30)
                }
            }
        }
        .padding(18)
        .glassSurface(radius: 22)
    }

    private var yAxisLabels: some View {
        VStack(alignment: .leading) {
            Text("100").axisStyle()
            Spacer()
            Text("50").axisStyle()
            Spacer()
            Text("0").axisStyle()
        }
        .frame(width: 26, height: 150)
    }

    private func timeframeLabel() -> String {
        switch timeframe {
        case "WEEK":  return "Last 7 days"
        case "MONTH": return "Last 30 days"
        case "YEAR":  return "Last 365 days"
        default:      return ""
        }
    }
}

private extension Text {
    func axisStyle() -> some View {
        self.font(.system(size: 10, weight: .medium))
            .foregroundStyle(Theme.Colors.espressoLight.opacity(0.7))
    }
}

private struct LineAreaChart: View {
    let values: [Double]
    let color: Color

    var body: some View {
        GeometryReader { geo in
            let path = smoothPath(in: geo.size)
            ZStack {
                // Faint gridlines
                ForEach(0..<3) { i in
                    let y = geo.size.height * CGFloat(i) / 2
                    Path { p in
                        p.move(to: CGPoint(x: 0, y: y))
                        p.addLine(to: CGPoint(x: geo.size.width, y: y))
                    }
                    .stroke(Theme.Colors.neutral200.opacity(0.5), style: StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
                }

                path.addingLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
                    .addingLine(to: CGPoint(x: 0, y: geo.size.height))
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.36), color.opacity(0.08), color.opacity(0)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )

                path.stroke(color, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

                if let last = values.last {
                    let y = yPosition(for: last, height: geo.size.height)
                    Circle().fill(color).frame(width: 8, height: 8)
                        .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                        .position(x: geo.size.width - 4, y: y)
                }
            }
        }
    }

    private func smoothPath(in size: CGSize) -> Path {
        guard values.count > 1 else { return Path() }
        let stepX = size.width / CGFloat(values.count - 1)
        let pts: [CGPoint] = values.enumerated().map { i, v in
            CGPoint(x: CGFloat(i) * stepX, y: yPosition(for: v, height: size.height))
        }
        var p = Path()
        p.move(to: pts[0])
        for i in 1..<pts.count {
            let prev = pts[i - 1], curr = pts[i]
            let mid = CGPoint(x: (prev.x + curr.x) / 2, y: (prev.y + curr.y) / 2)
            if i == 1 { p.addLine(to: mid) }
            else      { p.addQuadCurve(to: mid, control: prev) }
            if i == pts.count - 1 { p.addQuadCurve(to: curr, control: prev) }
        }
        return p
    }

    private func yPosition(for value: Double, height: CGFloat) -> CGFloat {
        let normalized = CGFloat(max(0, min(value, 100)) / 100.0)
        return height - (normalized * (height - 10)) - 5
    }
}

private extension Path {
    func addingLine(to point: CGPoint) -> Path {
        var c = self
        c.addLine(to: point)
        return c
    }
}

// MARK: - Quality Bidirectional Bar Chart (Dekoda-style)

private struct QualityBidirectionalCard: View {
    @EnvironmentObject var userViewModel: UserViewModel
    let timeframe: String

    fileprivate enum QCategory: String, CaseIterable {
        case healthy = "Healthy"
        case hard    = "Hard"
        case loose   = "Loose"
        case liquid  = "Liquid"

        var color: Color {
            switch self {
            case .healthy: return Theme.Colors.dataGreen
            case .hard:    return Theme.Colors.dataPink
            case .loose:   return Theme.Colors.dataBlue
            case .liquid:  return Theme.Colors.dataLiquid
            }
        }

        var sortIndex: Int {
            switch self {
            case .healthy: return 0
            case .hard:    return 1
            case .loose:   return 2
            case .liquid:  return 3
            }
        }
    }

    private struct ChartRow: Identifiable, Hashable {
        let id = UUID()
        let day: Date
        let category: QCategory
        let signed: Int  // healthy is positive, others are negative

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        static func == (l: ChartRow, r: ChartRow) -> Bool { l.id == r.id }
    }

    private static func categorize(_ type: Log.PoopType) -> QCategory {
        switch type {
        case .smoothSausage, .crackedSausage:       return .healthy
        case .separateHardLumps, .lumpySausage:     return .hard
        case .softBlobs, .fluffyPieces:             return .loose
        case .watery:                               return .liquid
        }
    }

    private var data: [ChartRow] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let bucketCount: Int = {
            switch timeframe {
            case "WEEK":  return 7
            case "MONTH": return 30
            case "YEAR":  return 12
            default: return 7
            }
        }()
        let isYear = timeframe == "YEAR"

        var rows: [ChartRow] = []
        for offset in (0..<bucketCount).reversed() {
            guard let bucketDate = isYear
                ? cal.date(byAdding: .month, value: -offset, to: today)
                : cal.date(byAdding: .day, value: -offset, to: today)
            else { continue }

            let logs: [Log] = {
                if isYear {
                    let c = cal.dateComponents([.year, .month], from: bucketDate)
                    return userViewModel.logHistory.filter {
                        let lc = cal.dateComponents([.year, .month], from: $0.timestamp)
                        return lc.year == c.year && lc.month == c.month
                    }
                } else {
                    return userViewModel.logHistory.filter { cal.isDate($0.timestamp, inSameDayAs: bucketDate) }
                }
            }()

            var counts: [QCategory: Int] = [.healthy: 0, .hard: 0, .loose: 0, .liquid: 0]
            for log in logs { counts[Self.categorize(log.type), default: 0] += 1 }

            for cat in QCategory.allCases where (counts[cat] ?? 0) > 0 {
                let v = counts[cat] ?? 0
                let signed = cat == .healthy ? v : -v
                rows.append(ChartRow(day: bucketDate, category: cat, signed: signed))
            }
        }
        return rows
    }

    private var totals: (healthy: Int, hard: Int, loose: Int, liquid: Int, total: Int) {
        var h = 0, hd = 0, l = 0, lq = 0
        for row in data {
            let n = abs(row.signed)
            switch row.category {
            case .healthy: h += n
            case .hard:    hd += n
            case .loose:   l += n
            case .liquid:  lq += n
            }
        }
        return (h, hd, l, lq, h + hd + l + lq)
    }

    private var yScale: Int {
        // Use max stacked off vs healthy per bucket
        let cal = Calendar.current
        let grouped = Dictionary(grouping: data) { row in
            cal.startOfDay(for: row.day)
        }
        let perDay = grouped.values.map { rows -> Int in
            let up   = rows.filter { $0.category == .healthy }.reduce(0) { $0 + abs($1.signed) }
            let down = rows.filter { $0.category != .healthy }.reduce(0) { $0 + abs($1.signed) }
            return max(up, down)
        }
        return max(perDay.max() ?? 1, 2)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Quality")
                        .font(Theme.Fonts.subheading(18))
                        .foregroundStyle(Theme.Colors.espresso)
                    Text("\(totals.total) total")
                        .font(Theme.Fonts.caption(12))
                        .foregroundStyle(Theme.Colors.espressoLight)
                }
                Spacer()
            }

            ZStack {
                Chart {
                    ForEach(data) { row in
                        BarMark(
                            x: .value("Day", row.day, unit: xUnit),
                            y: .value("Count", row.signed)
                        )
                        .foregroundStyle(row.category.color.gradient)
                        .cornerRadius(3)
                    }

                    RuleMark(y: .value("Zero", 0))
                        .foregroundStyle(Theme.Colors.espresso.opacity(0.22))
                        .lineStyle(StrokeStyle(lineWidth: 0.8))
                }
                .chartYScale(domain: -yScale...yScale)
                .chartYAxis {
                    AxisMarks(position: .leading, values: [-yScale, 0, yScale]) { v in
                        AxisValueLabel {
                            if let i = v.as(Int.self) {
                                Text("\(abs(i))")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundStyle(Theme.Colors.espressoLight.opacity(0.7))
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: xUnit, count: xStride)) { v in
                        AxisValueLabel {
                            if let date = v.as(Date.self) {
                                Text(formatX(date))
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundStyle(Theme.Colors.espressoLight.opacity(0.7))
                            }
                        }
                    }
                }
                .frame(height: 180)

                if totals.total == 0 {
                    Text("No data yet")
                        .font(Theme.Fonts.caption(13))
                        .foregroundStyle(Theme.Colors.espressoLight)
                }
            }

            // Dekoda-style legend rows: each category w/ count + %
            VStack(spacing: 6) {
                QualityLegendRow(category: .healthy, count: totals.healthy, total: totals.total)
                QualityLegendRow(category: .hard,    count: totals.hard,    total: totals.total)
                QualityLegendRow(category: .loose,   count: totals.loose,   total: totals.total)
                QualityLegendRow(category: .liquid,  count: totals.liquid,  total: totals.total)
            }
            .padding(.top, 4)
        }
        .padding(18)
        .glassSurface(radius: 22)
    }

    private var xUnit: Calendar.Component {
        timeframe == "YEAR" ? .month : .day
    }

    private var xStride: Int {
        switch timeframe {
        case "WEEK":  return 1
        case "MONTH": return 7
        case "YEAR":  return 2
        default: return 1
        }
    }

    private func formatX(_ date: Date) -> String {
        let f = DateFormatter()
        switch timeframe {
        case "MONTH": f.dateFormat = "M/d"
        case "YEAR":  f.dateFormat = "MMM"
        default:      f.dateFormat = "E"
        }
        return f.string(from: date)
    }
}

private struct QualityLegendRow: View {
    fileprivate let category: QualityBidirectionalCard.QCategory
    let count: Int
    let total: Int

    private var pct: Int { total > 0 ? Int(Double(count) / Double(total) * 100) : 0 }

    var body: some View {
        HStack(spacing: 10) {
            Capsule()
                .fill(category.color)
                .frame(width: 18, height: 7)
            Text(category.rawValue)
                .font(Theme.Fonts.bodyBold(13))
                .foregroundStyle(Theme.Colors.espresso)
            Spacer()
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text("\(count)")
                    .font(Theme.Fonts.bodyBold(13))
                    .foregroundStyle(Theme.Colors.espresso)
                Text("(\(pct)%)")
                    .font(Theme.Fonts.caption(11))
                    .foregroundStyle(Theme.Colors.espressoLight)
            }
        }
    }
}

// MARK: - Regularity Clock (24h)

private struct RegularityClockCard: View {
    @EnvironmentObject var userViewModel: UserViewModel

    private var hourCounts: [Int] {
        var counts = Array(repeating: 0, count: 24)
        let cal = Calendar.current
        for log in userViewModel.logHistory {
            counts[cal.component(.hour, from: log.timestamp)] += 1
        }
        return counts
    }

    private var maxCount: Int { hourCounts.max() ?? 1 }

    private var peakHourLabel: String {
        guard let peak = hourCounts.enumerated().max(by: { $0.element < $1.element }),
              peak.element > 0 else { return "—" }
        let h = peak.offset
        if h == 0 { return "12am" }
        if h < 12 { return "\(h)am" }
        if h == 12 { return "12pm" }
        return "\(h - 12)pm"
    }

    private var hasLogs: Bool { userViewModel.logHistory.isEmpty == false }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Regularity")
                        .font(Theme.Fonts.subheading(18))
                        .foregroundStyle(Theme.Colors.espresso)
                    Text("When you usually go")
                        .font(Theme.Fonts.caption(12))
                        .foregroundStyle(Theme.Colors.espressoLight)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(peakHourLabel)
                        .font(Theme.Fonts.hero(28))
                        .foregroundStyle(Theme.Colors.espresso)
                    Text("PEAK")
                        .font(Theme.Fonts.label(9))
                        .tracking(1.4)
                        .foregroundStyle(Theme.Colors.espressoLight)
                }
            }

            ZStack {
                RegularityClock(hourCounts: hourCounts, maxCount: maxCount)
                    .frame(width: 220, height: 220)

                if !hasLogs {
                    Text("Log a few poops to see your pattern")
                        .font(Theme.Fonts.caption(13))
                        .foregroundStyle(Theme.Colors.espressoLight)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(18)
        .glassSurface(radius: 22)
    }
}

/// 24-hour radial pie chart. Each hour is a filled wedge.
/// Wedge opacity scales with the count for that hour. Noon at top, midnight at bottom.
private struct RegularityClock: View {
    let hourCounts: [Int]
    let maxCount: Int

    var body: some View {
        GeometryReader { geo in
            let cx = geo.size.width / 2
            let cy = geo.size.height / 2
            let labelInset: CGFloat = 24
            let pieRadius = min(geo.size.width, geo.size.height) / 2 - labelInset
            let labelRadius = pieRadius + 14

            ZStack {
                // Pie wedges — day hours warm caramel, night hours baby blue, opacity = intensity
                Canvas { ctx, _ in
                    for hour in 0..<24 {
                        let count = hourCounts[hour]
                        let intensity = CGFloat(count) / CGFloat(max(maxCount, 1))
                        // Faint base + intensity-driven boost
                        let alpha = 0.12 + 0.68 * intensity
                        let isDay = hour >= 6 && hour < 18
                        let baseColor = isDay ? Theme.Colors.caramel400 : Theme.Colors.babyBlue400

                        // Noon at top: hour 12 → angle -90°
                        let start = Angle.degrees(Double(hour - 12) / 24.0 * 360.0 - 90.0)
                        let end   = Angle.degrees(Double(hour - 11) / 24.0 * 360.0 - 90.0)

                        var path = Path()
                        path.move(to: CGPoint(x: cx, y: cy))
                        path.addArc(
                            center: CGPoint(x: cx, y: cy),
                            radius: pieRadius,
                            startAngle: start,
                            endAngle: end,
                            clockwise: false
                        )
                        path.closeSubpath()

                        ctx.fill(path, with: .color(baseColor.opacity(alpha)))
                    }

                    // Thin white separators between wedges so they read as discrete slices
                    for hour in 0..<24 {
                        let angleDeg = Double(hour - 12) / 24.0 * 360.0 - 90.0
                        let a = CGFloat(angleDeg * .pi / 180)
                        var line = Path()
                        line.move(to: CGPoint(x: cx, y: cy))
                        line.addLine(to: CGPoint(
                            x: cx + cos(a) * pieRadius,
                            y: cy + sin(a) * pieRadius
                        ))
                        ctx.stroke(line, with: .color(Theme.Colors.cream), lineWidth: 0.6)
                    }
                }

                // Hour labels: 12pm top, 6pm right, 12am bottom, 6am left
                clockLabel("12pm", angleDeg: -90, cx: cx, cy: cy, r: labelRadius)
                clockLabel("6pm",  angleDeg: 0,   cx: cx, cy: cy, r: labelRadius)
                clockLabel("12am", angleDeg: 90,  cx: cx, cy: cy, r: labelRadius)
                clockLabel("6am",  angleDeg: 180, cx: cx, cy: cy, r: labelRadius)

                // Sun above 12pm, moon below 12am
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Theme.Colors.dataYellow)
                    .position(x: cx + 28, y: cy - labelRadius)

                Image(systemName: "moon.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Theme.Colors.dataLoose)
                    .position(x: cx + 28, y: cy + labelRadius)
            }
        }
    }

    @ViewBuilder
    private func clockLabel(_ text: String, angleDeg deg: Double, cx: CGFloat, cy: CGFloat, r: CGFloat) -> some View {
        let radians = CGFloat(deg * .pi / 180)
        Text(text)
            .font(Theme.Fonts.label(10))
            .foregroundStyle(Theme.Colors.espressoLight)
            .position(x: cx + cos(radians) * r, y: cy + sin(radians) * r)
    }
}

// MARK: - Frequency Bar Chart

private struct FrequencyBarCard: View {
    @EnvironmentObject var userViewModel: UserViewModel
    let timeframe: String

    private struct DayCount: Identifiable {
        let id = UUID()
        let day: Date
        let count: Int
        let avgScore: Int      // 0 if no logs
    }

    private var data: [DayCount] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let count: Int = {
            switch timeframe {
            case "WEEK":  return 7
            case "MONTH": return 30
            case "YEAR":  return 12
            default: return 7
            }
        }()
        if timeframe == "YEAR" {
            return (0..<12).reversed().map { offset -> DayCount in
                guard let month = cal.date(byAdding: .month, value: -offset, to: today) else {
                    return DayCount(day: today, count: 0, avgScore: 0)
                }
                let comps = cal.dateComponents([.year, .month], from: month)
                let logs = userViewModel.logHistory.filter {
                    let c = cal.dateComponents([.year, .month], from: $0.timestamp)
                    return c.year == comps.year && c.month == comps.month
                }
                let days = cal.range(of: .day, in: .month, for: month)?.count ?? 30
                let avgScore = logs.isEmpty ? 0
                    : logs.map { UserViewModel.calculatePoopScoreStatic(for: $0) }.reduce(0, +) / logs.count
                return DayCount(day: month, count: logs.count / days, avgScore: avgScore)
            }
        }
        return (0..<count).reversed().map { offset -> DayCount in
            guard let day = cal.date(byAdding: .day, value: -offset, to: today) else {
                return DayCount(day: today, count: 0, avgScore: 0)
            }
            let logs = userViewModel.logHistory.filter { cal.isDate($0.timestamp, inSameDayAs: day) }
            let avgScore = logs.isEmpty ? 0
                : logs.map { UserViewModel.calculatePoopScoreStatic(for: $0) }.reduce(0, +) / logs.count
            return DayCount(day: day, count: logs.count, avgScore: avgScore)
        }
    }

    private var avgPerDay: Double {
        let total = data.reduce(0) { $0 + $1.count }
        return Double(total) / max(Double(data.count), 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Frequency")
                        .font(Theme.Fonts.subheading(18))
                        .foregroundStyle(Theme.Colors.espresso)
                    Text("Poops per day")
                        .font(Theme.Fonts.caption(12))
                        .foregroundStyle(Theme.Colors.espressoLight)
                }
                Spacer()
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(String(format: "%.1f", avgPerDay))
                        .font(Theme.Fonts.hero(28))
                        .foregroundStyle(Theme.Colors.espresso)
                    Text("avg/day")
                        .font(Theme.Fonts.captionBold(11))
                        .foregroundStyle(Theme.Colors.espressoLight)
                }
            }

            ZStack {
                Chart {
                    ForEach(data) { row in
                        BarMark(
                            x: .value("Day", row.day, unit: timeframe == "YEAR" ? .month : .day),
                            y: .value("Poops", row.count)
                        )
                        .foregroundStyle(barColor(for: row).gradient)
                        .cornerRadius(4)
                    }
                    RuleMark(y: .value("Target", 1))
                        .foregroundStyle(Theme.Colors.espresso.opacity(0.25))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { v in
                        AxisValueLabel {
                            if let i = v.as(Int.self) {
                                Text("\(i)")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundStyle(Theme.Colors.espressoLight.opacity(0.7))
                            }
                        }
                    }
                }
                .frame(height: 120)

                if avgPerDay == 0 {
                    Text("No data yet")
                        .font(Theme.Fonts.caption(13))
                        .foregroundStyle(Theme.Colors.espressoLight)
                }
            }
        }
        .padding(18)
        .glassSurface(radius: 22)
    }

    /// Bar color: score-band for logged days, neutral for empty days.
    private func barColor(for row: DayCount) -> Color {
        guard row.count > 0 else { return Theme.Colors.neutral300 }
        return scoreBandColor(row.avgScore)
    }
}

// MARK: - Calendar with Green Zone day coloring

private struct CalendarCard: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @Binding var selectedMonth: Date
    @Binding var selectedDate: Date
    @Binding var dayLogsModalDate: Date?

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
                    chevron(name: "chevron.left")
                }

                Spacer()
                Text(monthTitle)
                    .font(Theme.Fonts.subheading(17))
                    .foregroundStyle(Theme.Colors.espresso)
                Spacer()

                Button {
                    Theme.Haptics.light()
                    if let m = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) {
                        withAnimation(Theme.Animation.spring) { selectedMonth = m }
                    }
                } label: {
                    chevron(name: "chevron.right")
                }
            }

            HStack(spacing: 0) {
                ForEach(["S","M","T","W","T","F","S"], id: \.self) { l in
                    Text(l)
                        .font(Theme.Fonts.label(9))
                        .foregroundStyle(Theme.Colors.espressoLight.opacity(0.7))
                        .frame(maxWidth: .infinity)
                }
            }

            let days = monthDays(for: selectedMonth)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 6) {
                ForEach(Array(days.enumerated()), id: \.element.id) { idx, day in
                    let isGreen = !day.ignored && userViewModel.isGreenZoneDay(day.date)
                    let leftConnected = isGreen && idx > 0
                        && !days[idx - 1].ignored
                        && userViewModel.isGreenZoneDay(days[idx - 1].date)
                    let rightConnected = isGreen && idx < days.count - 1
                        && !days[idx + 1].ignored
                        && userViewModel.isGreenZoneDay(days[idx + 1].date)

                    CalendarDayCell(
                        date: day.date,
                        isIgnored: day.ignored,
                        isGreenZone: isGreen,
                        hasLogs: userViewModel.dayHasLogs(day.date),
                        leftConnected: leftConnected,
                        rightConnected: rightConnected,
                        onTap: {
                            guard !day.ignored else { return }
                            guard userViewModel.dayHasLogs(day.date) else { return }
                            Theme.Haptics.light()
                            selectedDate = day.date
                            dayLogsModalDate = day.date
                        }
                    )
                }
            }

            // Legend
            HStack(spacing: 8) {
                Capsule()
                    .fill(Theme.Colors.dataGreen)
                    .frame(width: 18, height: 8)
                Text("Green Zone day")
                    .font(Theme.Fonts.caption(11))
                    .foregroundStyle(Theme.Colors.espressoLight)
                Spacer()
            }
            .padding(.top, 6)
        }
        .padding(18)
        .glassSurface(radius: 22)
    }

    private func chevron(name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(Theme.Colors.espresso)
            .frame(width: 30, height: 30)
            .background(Circle().fill(Color.white.opacity(0.6)))
            .overlay(Circle().stroke(Color.white.opacity(0.7), lineWidth: 1))
    }

    private func monthDays(for month: Date) -> [TempDay] {
        var days: [TempDay] = []
        let cal = Calendar.current
        let f = DateFormatter(); f.dateFormat = "dd"

        guard let range = cal.range(of: .day, in: .month, for: month)?.compactMap({
            value -> Date? in cal.date(byAdding: .day, value: value - 1, to: month)
        }) else { return days }

        let firstWeekday = cal.component(.weekday, from: range.first!)
        for index in Array(0..<firstWeekday - 1).reversed() {
            guard let d = cal.date(byAdding: .day, value: -index - 1, to: range.first!) else { return days }
            days.append(.init(shortSymbol: f.string(from: d), date: d, ignored: true))
        }
        for d in range {
            days.append(.init(shortSymbol: f.string(from: d), date: d))
        }
        let lastWeekday = 7 - cal.component(.weekday, from: range.last!)
        if lastWeekday > 0 {
            for index in 0..<lastWeekday {
                guard let d = cal.date(byAdding: .day, value: index + 1, to: range.last!) else { return days }
                days.append(.init(shortSymbol: f.string(from: d), date: d, ignored: true))
            }
        }
        return days
    }
}

private struct CalendarDayCell: View {
    let date: Date
    let isIgnored: Bool
    let isGreenZone: Bool
    let hasLogs: Bool
    let leftConnected: Bool
    let rightConnected: Bool
    let onTap: () -> Void

    private var dayNum: String {
        let f = DateFormatter(); f.dateFormat = "d"
        return f.string(from: date)
    }

    // Pill corners adapt to connection: flat where it joins, rounded where it ends.
    private var corners: (lead: CGFloat, trail: CGFloat) {
        let r: CGFloat = 16
        return (leftConnected ? 0 : r, rightConnected ? 0 : r)
    }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                if isGreenZone {
                    UnevenRoundedRectangle(
                        topLeadingRadius: corners.lead,
                        bottomLeadingRadius: corners.lead,
                        bottomTrailingRadius: corners.trail,
                        topTrailingRadius: corners.trail,
                        style: .continuous
                    )
                    .fill(Theme.Colors.dataGreen)
                    .frame(height: 32)
                    // Touch edge on connected sides for adjacent pills to merge.
                    .padding(.leading, leftConnected ? 0 : 3)
                    .padding(.trailing, rightConnected ? 0 : 3)
                } else {
                    Circle()
                        .fill(Theme.Colors.neutral200.opacity(0.4))
                        .frame(width: 30, height: 30)
                        .opacity(isIgnored ? 0.15 : (hasLogs ? 0.85 : 0.5))
                }

                Text(dayNum)
                    .font(Theme.Fonts.captionBold(11))
                    .foregroundStyle(
                        isIgnored
                            ? Theme.Colors.espressoLight.opacity(0.4)
                            : (isGreenZone ? .white : Theme.Colors.espresso)
                    )
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isIgnored || !hasLogs)
    }
}

// MARK: - Smart Insights

private struct SmartInsightsSection: View {
    @EnvironmentObject var userViewModel: UserViewModel
    let timeframe: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Smart Insights")
                .font(Theme.Fonts.subheading(18))
                .foregroundStyle(Theme.Colors.espresso)
                .padding(.horizontal, 4)

            let insights = userViewModel.generateAdvancedInsights(for: insightsTimeframe)
            if insights.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Theme.Colors.espressoLight)
                    Text("Log a few poops and we'll surface patterns here")
                        .font(Theme.Fonts.caption(13))
                        .foregroundStyle(Theme.Colors.espressoLight)
                    Spacer()
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassSurface(radius: 18)
            } else {
                ForEach(insights.prefix(5)) { insight in
                    AdvancedInsightCardGlass(insight: insight)
                }
            }
        }
    }

    // Insights generator doesn't know "YEAR" — fall back to MONTH.
    private var insightsTimeframe: String {
        timeframe == "YEAR" ? "MONTH" : timeframe
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
                            .foregroundStyle(Theme.Colors.espresso)
                        Spacer()
                        if let metric = insight.metric {
                            Text(metric)
                                .font(Theme.Fonts.captionBold(11))
                                .foregroundStyle(insight.iconColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(insight.iconColor.opacity(0.15)))
                        }
                    }
                    Text(insight.description)
                        .font(Theme.Fonts.caption(13))
                        .foregroundStyle(Theme.Colors.espressoMid)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if let actionable = insight.actionable {
                HStack(spacing: 6) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.Colors.dataAmber)
                    Text(actionable)
                        .font(Theme.Fonts.caption(12))
                        .foregroundStyle(Theme.Colors.espressoMid)
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
        CreamBackground()
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
