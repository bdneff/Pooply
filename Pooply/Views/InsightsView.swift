//
//  InsightsView.swift
//  Pooply
//
//  Redesigned Insights Page - Phase 4
//

import SwiftUI
import Charts

struct InsightsView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var subscriptionService: SubscriptionService
    @State private var selectedTimeframe = "WEEK"
    @State private var showPaywall = false

    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {

                    // MARK: - Header
                    InsightsHeader()
                        .padding(.horizontal, Theme.Spacing.screenHorizontal)

                    // MARK: - Timeframe Toggle
                    HStack {
                        Spacer()
                        TimeframeToggle(selected: $selectedTimeframe)
                        Spacer()
                    }
                    .padding(.horizontal, Theme.Spacing.screenHorizontal)

                    // MARK: - Chart Card (free for all)
                    WeeklyQualityChart(selectedTimeframe: selectedTimeframe)
                        .padding(.horizontal, Theme.Spacing.screenHorizontal)

                    // MARK: - Pattern Stats (free for all)
                    PatternStatsRow(timeframe: selectedTimeframe)
                        .padding(.horizontal, Theme.Spacing.screenHorizontal)

                    // MARK: - AI Insights (Pro) or Upsell Card (Free)
                    if subscriptionService.isSubscribed {
                        InsightsSection(timeframe: selectedTimeframe)
                            .padding(.horizontal, Theme.Spacing.screenHorizontal)
                    } else {
                        PooplyProCard(onUpgrade: { showPaywall = true })
                            .padding(.horizontal, Theme.Spacing.screenHorizontal)
                    }

                    // Bottom spacing for tab bar
                    Spacer().frame(height: 100)
                }
                .padding(.top, Theme.Spacing.md)
            }
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView()
                .environmentObject(subscriptionService)
        }
    }
}

// MARK: - Insights Header

struct InsightsHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Insights")
                .font(Theme.Fonts.title())
                .foregroundStyle(Theme.Colors.textPrimary)

            Text("Your gut health at a glance")
                .font(Theme.Fonts.body())
                .foregroundStyle(Theme.Colors.textTertiary)
        }
    }
}

// MARK: - Weekly Quality Chart

struct WeeklyQualityChart: View {
    @EnvironmentObject var userViewModel: UserViewModel
    let selectedTimeframe: String

    private var chartData: [ChartEntry] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let (start, days) = dateRange(for: selectedTimeframe, calendar: cal, today: today)
        let filteredLogs = userViewModel.getLogsForTimeframe(selectedTimeframe)

        let grouped = Dictionary(grouping: filteredLogs.filter { $0.timestamp >= start }) {
            cal.startOfDay(for: $0.timestamp)
        }

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

    private func dateRange(for timeframe: String, calendar: Calendar, today: Date) -> (start: Date, days: [Date]) {
        switch timeframe {
        case "TODAY":
            return (today, [today])
        case "WEEK":
            let start = calendar.date(byAdding: .day, value: -6, to: today)!
            let days = (0..<7).compactMap { calendar.date(byAdding: .day, value: -6 + $0, to: today) }
            return (start, days)
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

    private var yUpperBound: Int {
        let maxCount = chartData.map(\.count).max() ?? 1
        // Round up to next whole number with padding
        return max(maxCount + 1, 4)
    }

    private var timeframeLabel: String {
        switch selectedTimeframe {
        case "TODAY": return "Today"
        case "WEEK": return "Last 7 days"
        case "MONTH": return "Last 30 days"
        default: return "Last 7 days"
        }
    }

    private var chartTitle: String {
        switch selectedTimeframe {
        case "TODAY": return "Today's Quality"
        case "WEEK": return "Weekly Quality"
        case "MONTH": return "Monthly Quality"
        default: return "Weekly Quality"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Header
            HStack {
                Text(chartTitle)
                    .font(Theme.Fonts.subheading())
                    .foregroundStyle(Theme.Colors.textPrimary)

                Spacer()

                Text(timeframeLabel)
                    .font(Theme.Fonts.caption())
                    .foregroundStyle(Theme.Colors.textTertiary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Theme.Colors.backgroundSecondary)
                    .clipShape(Capsule())
            }

            // Chart - using Date for x-axis for proper spacing
            Chart {
                ForEach(chartData) { entry in
                    BarMark(
                        x: .value("Day", entry.day, unit: .day),
                        y: .value("Count", entry.count)
                    )
                    .foregroundStyle(entry.category.color.gradient)
                    .cornerRadius(3)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: Array(0...yUpperBound)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Theme.Colors.neutral.opacity(0.2))
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            Text("\(intValue)")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundStyle(Theme.Colors.textTertiary)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: selectedTimeframe == "MONTH" ? .day : .day, count: selectedTimeframe == "MONTH" ? 7 : 1)) { value in
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(formatXAxisLabel(date))
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundStyle(Theme.Colors.textTertiary)
                        }
                    }
                }
            }
            .chartYScale(domain: 0...yUpperBound)
            .chartXScale(domain: xAxisDomain)
            .frame(height: 180)
            .padding(.top, 8) // Extra padding so bars don't hit top
            .animation(Theme.Animation.spring, value: chartData)

            // Legend
            HStack(spacing: Theme.Spacing.lg) {
                ChartLegendItem(color: Theme.Colors.good, label: "Good")
                ChartLegendItem(color: Theme.Colors.hard, label: "Hard")
                ChartLegendItem(color: Theme.Colors.loose, label: "Loose")
            }
        }
        .padding(Theme.Spacing.cardPadding)
        .background(Theme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.large, style: .continuous))
        .cardShadow()
    }

    private var xAxisDomain: ClosedRange<Date> {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        switch selectedTimeframe {
        case "TODAY":
            let end = cal.date(byAdding: .day, value: 1, to: today)!
            return today...end
        case "WEEK":
            let start = cal.date(byAdding: .day, value: -6, to: today)!
            let end = cal.date(byAdding: .day, value: 1, to: today)!
            return start...end
        case "MONTH":
            let start = cal.date(byAdding: .day, value: -29, to: today)!
            let end = cal.date(byAdding: .day, value: 1, to: today)!
            return start...end
        default:
            let start = cal.date(byAdding: .day, value: -6, to: today)!
            let end = cal.date(byAdding: .day, value: 1, to: today)!
            return start...end
        }
    }

    private func formatXAxisLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        switch selectedTimeframe {
        case "TODAY":
            formatter.dateFormat = "h a"
        case "WEEK":
            formatter.dateFormat = "E"  // Mon, Tue, etc.
        case "MONTH":
            formatter.dateFormat = "M/d"  // 1/15, 1/22, etc.
        default:
            formatter.dateFormat = "E"
        }
        return formatter.string(from: date)
    }
}

// MARK: - Chart Entry

private struct ChartEntry: Identifiable, Equatable {
    let id = UUID()
    let day: Date
    let category: ChartCategory
    let count: Int
}

private enum ChartCategory: String {
    case regular, hard, loose

    var color: Color {
        switch self {
        case .regular: return Theme.Colors.good
        case .hard: return Theme.Colors.hard
        case .loose: return Theme.Colors.loose
        }
    }
}

// MARK: - Chart Legend Item

struct ChartLegendItem: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(label)
                .font(Theme.Fonts.caption())
                .foregroundStyle(Theme.Colors.textSecondary)
        }
    }
}

// MARK: - Pattern Stats Row

struct PatternStatsRow: View {
    @EnvironmentObject var userViewModel: UserViewModel
    let timeframe: String

    var body: some View {
        let stats = userViewModel.getPatternStats(for: timeframe)

        HStack(spacing: Theme.Spacing.sm) {
            ForEach(stats) { stat in
                PatternStatCard(stat: stat)
            }
        }
    }
}

struct PatternStatCard: View {
    let stat: UserViewModel.PatternStat

    var body: some View {
        VStack(spacing: 4) {
            Text(stat.value)
                .font(Theme.Fonts.heading(24))
                .foregroundStyle(Theme.Colors.textPrimary)
                .contentTransition(.numericText())

            Text(stat.label)
                .font(Theme.Fonts.label(10))
                .foregroundStyle(Theme.Colors.textTertiary)
                .tracking(0.3)

            if let trend = stat.trend, let trendValue = stat.trendValue {
                HStack(spacing: 2) {
                    Image(systemName: trend == "up" ? "arrow.up" : "arrow.down")
                        .font(.system(size: 8, weight: .bold))
                    Text(trendValue)
                        .font(Theme.Fonts.micro())
                }
                .foregroundStyle(trend == "up" ? Theme.Colors.good : Theme.Colors.blood)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.md)
        .background(Theme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous))
        .cardShadow()
    }
}

// MARK: - Insights Section (Advanced)

struct InsightsSection: View {
    @EnvironmentObject var userViewModel: UserViewModel
    let timeframe: String

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionHeader(title: "Smart Insights")

            let insights = userViewModel.generateAdvancedInsights(for: timeframe)

            LazyVStack(spacing: Theme.Spacing.sm) {
                ForEach(insights) { insight in
                    AdvancedInsightCard(insight: insight)
                }
            }
        }
    }
}

struct AdvancedInsightCard: View {
    let insight: UserViewModel.AdvancedInsight

    private var priorityColor: Color {
        switch insight.priority {
        case .critical: return Theme.Colors.red
        case .high: return Theme.Colors.orange
        case .medium: return Theme.Colors.primary
        case .low: return Theme.Colors.neutral
        }
    }

    private var typeLabel: String {
        insight.type.rawValue.uppercased()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main content row
            HStack(alignment: .top, spacing: Theme.Spacing.md) {
                // Icon with priority indicator
                ZStack(alignment: .topTrailing) {
                    Image(systemName: insight.icon)
                        .font(.system(size: 20))
                        .foregroundStyle(insight.iconColor)
                        .frame(width: 44, height: 44)
                        .background(insight.iconColor.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    // Priority dot for high/critical
                    if insight.priority == .critical || insight.priority == .high {
                        Circle()
                            .fill(priorityColor)
                            .frame(width: 10, height: 10)
                            .overlay(
                                Circle()
                                    .stroke(Theme.Colors.cardBackground, lineWidth: 2)
                            )
                            .offset(x: 4, y: -4)
                    }
                }

                // Content
                VStack(alignment: .leading, spacing: 6) {
                    // Type badge and metric
                    HStack(spacing: Theme.Spacing.sm) {
                        Text(typeLabel)
                            .font(Theme.Fonts.label(9))
                            .foregroundStyle(priorityColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(priorityColor.opacity(0.12))
                            .clipShape(Capsule())

                        Spacer()

                        // Metric badge
                        if let metric = insight.metric {
                            Text(metric)
                                .font(Theme.Fonts.captionBold())
                                .foregroundStyle(insight.iconColor)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(insight.iconColor.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }

                    // Title
                    Text(insight.title)
                        .font(Theme.Fonts.bodyBold())
                        .foregroundStyle(Theme.Colors.textPrimary)

                    // Description
                    Text(insight.description)
                        .font(Theme.Fonts.caption())
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // Actionable recommendation
            if let actionable = insight.actionable {
                Divider()
                    .padding(.top, Theme.Spacing.md)

                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.Colors.fiber)

                    Text(actionable)
                        .font(Theme.Fonts.caption())
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .italic()
                }
                .padding(.top, Theme.Spacing.sm)
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous))
        .cardShadow()
    }
}

// MARK: - Preview

#Preview {
    InsightsView()
        .environmentObject(
            UserViewModel(
                user: User(name: "Jessica", age: 25, weight: 160, gender: "female"),
                withDummyData: true
            )
        )
        .environmentObject(SubscriptionService.shared)
}
