//
//  HomeView.swift
//  Pooply
//
//  Redesigned Home Page - Phase 3
//

import SwiftUI
import FirebaseAnalytics

struct HomeView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @Binding var showCameraView: Bool
    @Binding var showManualEntry: Bool
    @Binding var showProfileModal: Bool

    @State private var showDayLogsModal = false
    @State private var selectedTimeframe = "WEEK"
    @State private var selectedMonth: Date = .currentMonth
    @State private var selectedDate: Date = .now

    var selectedMonthDates: [TempDay] {
        return extractDates(selectedMonth)
    }

    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {

                    // MARK: - Header / Greeting
                    GreetingHeader(
                        userName: userViewModel.user.name,
                        onProfileTap: { showProfileModal = true }
                    )
                    .padding(.horizontal, Theme.Spacing.screenHorizontal)

                    // MARK: - Poop Score Hero Card
                    PoopScoreCard(
                        score: userViewModel.averagePoopScore(for: selectedTimeframe),
                        goodCount: userViewModel.goodLogCount(for: selectedTimeframe),
                        totalCount: userViewModel.totalLogCount(for: selectedTimeframe),
                        selectedTimeframe: $selectedTimeframe
                    )
                    .padding(.horizontal, Theme.Spacing.screenHorizontal)

                    // MARK: - Mini Stat Cards
                    HStack(spacing: 12) {
                        MiniStatCard(
                            value: Int(userViewModel.averageHydrationPercentage(for: selectedTimeframe) * 100),
                            label: "Hydration",
                            icon: "drop.fill",
                            color: Theme.Colors.hydration,
                            progress: userViewModel.averageHydrationPercentage(for: selectedTimeframe)
                        )

                        MiniStatCard(
                            value: Int(userViewModel.averageBloodPercentage(for: selectedTimeframe) * 100),
                            label: "Blood",
                            icon: "heart.fill",
                            color: Theme.Colors.blood,
                            progress: userViewModel.averageBloodPercentage(for: selectedTimeframe),
                            invertColor: true
                        )

                        MiniStatCard(
                            value: Int(userViewModel.averageFiberPercentage(for: selectedTimeframe) * 100),
                            label: "Fiber",
                            icon: "leaf.fill",
                            color: Theme.Colors.fiber,
                            progress: userViewModel.averageFiberPercentage(for: selectedTimeframe)
                        )
                    }
                    .padding(.horizontal, Theme.Spacing.screenHorizontal)

                    // MARK: - Streaks
                    StreaksRow(
                        currentStreak: userViewModel.regularStreak,
                        longestStreak: userViewModel.longestRegularStreak
                    )
                    .padding(.horizontal, Theme.Spacing.screenHorizontal)

                    // MARK: - Calendar Card
                    CalendarCard(
                        selectedMonth: $selectedMonth,
                        selectedDate: $selectedDate,
                        showDayLogsModal: $showDayLogsModal
                    )
                    .padding(.horizontal, Theme.Spacing.screenHorizontal)

                    // MARK: - Recent Logs
                    RecentLogsSection()
                        .padding(.horizontal, Theme.Spacing.screenHorizontal)

                    // Bottom spacing for tab bar
                    Spacer().frame(height: 100)
                }
                .padding(.top, Theme.Spacing.md)
            }
        }
        .sheet(isPresented: $showDayLogsModal) {
            DayLogsModal(selectedDate: selectedDate, isPresented: $showDayLogsModal)
        }
        .onAppear {
            Analytics.logEvent("home_viewed", parameters: nil)
        }
    }
}

// MARK: - Greeting Header

struct GreetingHeader: View {
    let userName: String
    let onProfileTap: () -> Void

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Hi, \(userName)")
                    .font(Theme.Fonts.title())
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text("How's your gut today?")
                    .font(Theme.Fonts.body())
                    .foregroundStyle(Theme.Colors.textTertiary)
            }

            Spacer()

            // Profile Button
            Button(action: {
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
                onProfileTap()
            }) {
                MascotCircle(size: 44)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Poop Score Card

struct PoopScoreCard: View {
    let score: Int
    let goodCount: Int
    let totalCount: Int
    @Binding var selectedTimeframe: String
    @EnvironmentObject var userViewModel: UserViewModel

    @State private var animatedScore: Double = 0
    @State private var showShareSheet = false

    private var scoreColor: Color {
        switch score {
        case 80...100: return Theme.Colors.good
        case 60..<80: return Theme.Colors.fiber
        case 40..<60: return Theme.Colors.hard
        default: return Theme.Colors.blood
        }
    }

    private var timeframeLabel: String {
        switch selectedTimeframe {
        case "TODAY": return "Today"
        case "WEEK": return "This Week"
        case "MONTH": return "This Month"
        default: return "This Week"
        }
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
            // Centered timeframe picker
            TimeframeToggle(selected: $selectedTimeframe)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 8.0)

            // Score Display - centered
            ZStack {
                // Arc background
                ArcShape(startAngle: .degrees(-210), endAngle: .degrees(30))
                    .stroke(scoreColor.opacity(0.2), style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .frame(width: 160, height: 160)

                // Arc progress
                ArcShape(startAngle: .degrees(-210), endAngle: .degrees(-210 + 240 * (animatedScore / 100)))
                    .stroke(scoreColor, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .frame(width: 160, height: 160)

                // Score text
                VStack(spacing: 2) {
                    HStack(alignment: .top, spacing: 2) {
                        Text("\(Int(animatedScore))")
                            .font(Theme.Fonts.hero(48))
                            .foregroundStyle(Theme.Colors.textPrimary)
                            .contentTransition(.numericText())

                        Text("%")
                            .font(Theme.Fonts.title(20))
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .offset(y: 6)
                    }

                    Text("POOP SCORE")
                        .font(Theme.Fonts.label(11))
                        .foregroundStyle(Theme.Colors.textTertiary)
                        .tracking(1)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 170)
            
            VStack {
                // Summary text - centered
                if totalCount > 0 {
                    Text("\(goodCount) of \(totalCount) logs were good")
                        .font(Theme.Fonts.caption())
                        .foregroundStyle(Theme.Colors.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    Text("No logs yet for this period")
                        .font(Theme.Fonts.caption())
                        .foregroundStyle(Theme.Colors.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }

                // Share Score button (only with logs)
                if totalCount > 0 {
                    Button(action: {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        showShareSheet = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Share Score")
                                .font(Theme.Fonts.captionBold())
                        }
                        .foregroundStyle(Theme.Colors.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Theme.Colors.primary.opacity(0.12))
                        .clipShape(Capsule())
                    }
                }
            }
            .offset(y: -24)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animatedScore = Double(score)
            }
        }
        .onChange(of: score) { _, newValue in
            withAnimation(.easeOut(duration: 0.6)) {
                animatedScore = Double(newValue)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareOptionsSheet(
                score: score,
                goodCount: goodCount,
                totalCount: totalCount,
                timeframe: timeframeLabel
            )
            .environmentObject(userViewModel)
        }
    }
}

// MARK: - Share Options Sheet

struct ShareOptionsSheet: View {
    let score: Int
    let goodCount: Int
    let totalCount: Int
    let timeframe: String
    @EnvironmentObject var userViewModel: UserViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var selectedOption: ShareOption = .scoreGauge

    enum ShareOption: String, CaseIterable {
        case progressGraph, scoreGauge, calendar

        var title: String {
            switch self {
            case .progressGraph: return "Progress"
            case .scoreGauge: return "Score"
            case .calendar: return "Calendar"
            }
        }

        var icon: String {
            switch self {
            case .progressGraph: return "chart.xyaxis.line"
            case .scoreGauge: return "gauge.medium"
            case .calendar: return "calendar"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()

                VStack(spacing: Theme.Spacing.md) {
                    Text("Share Your Progress")
                        .font(Theme.Fonts.heading())
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .padding(.top, Theme.Spacing.sm)

                    // Option selector row
                    HStack(spacing: Theme.Spacing.sm) {
                        ForEach(ShareOption.allCases, id: \.rawValue) { option in
                            ShareOptionThumbnail(
                                option: option,
                                isSelected: selectedOption == option
                            ) {
                                withAnimation(Theme.Animation.spring) {
                                    selectedOption = option
                                }
                            }
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.screenHorizontal)

                    // Selected card preview
                    ScrollView(.vertical, showsIndicators: false) {
                        Group {
                            switch selectedOption {
                            case .progressGraph:
                                ShareableProgressCard(
                                    timeframe: timeframe,
                                    logHistory: userViewModel.logHistory,
                                    calculateScore: { UserViewModel.calculatePoopScoreStatic(for: $0) }
                                )
                            case .scoreGauge:
                                ShareableScoreCard(
                                    score: score,
                                    goodCount: goodCount,
                                    totalCount: totalCount,
                                    timeframe: timeframe
                                )
                            case .calendar:
                                ShareableCalendarCard(
                                    logHistory: userViewModel.logHistory,
                                    calculateScore: { UserViewModel.calculatePoopScoreStatic(for: $0) }
                                )
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.lg)
                    }

                    // Share button
                    Button(action: shareCard) {
                        HStack(spacing: Theme.Spacing.sm) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Share")
                                .font(Theme.Fonts.bodyBold())
                        }
                        .foregroundStyle(Theme.Colors.textOnPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Theme.Colors.primary)
                        .clipShape(Capsule())
                    }
                    .padding(.horizontal, Theme.Spacing.screenHorizontal)

                    Spacer().frame(height: Theme.Spacing.md)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(Theme.Fonts.bodyBold())
                    .foregroundStyle(Theme.Colors.primary)
                }
            }
        }
    }

    @MainActor
    private func shareCard() {
        let cardView: AnyView
        switch selectedOption {
        case .progressGraph:
            cardView = AnyView(ShareableProgressCard(
                timeframe: timeframe,
                logHistory: userViewModel.logHistory,
                calculateScore: { UserViewModel.calculatePoopScoreStatic(for: $0) }
            ))
        case .scoreGauge:
            cardView = AnyView(ShareableScoreCard(
                score: score,
                goodCount: goodCount,
                totalCount: totalCount,
                timeframe: timeframe
            ))
        case .calendar:
            cardView = AnyView(ShareableCalendarCard(
                logHistory: userViewModel.logHistory,
                calculateScore: { UserViewModel.calculatePoopScoreStatic(for: $0) }
            ))
        }

        let renderer = ImageRenderer(content: cardView.frame(width: 350))
        renderer.scale = 3.0

        if let image = renderer.uiImage {
            let activityVC = UIActivityViewController(
                activityItems: [image, "Check out my gut health on Pooply!"],
                applicationActivities: nil
            )

            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                var topVC = rootVC
                while let presented = topVC.presentedViewController {
                    topVC = presented
                }
                topVC.present(activityVC, animated: true)
            }
        }
    }
}

// MARK: - Share Option Thumbnail

struct ShareOptionThumbnail: View {
    let option: ShareOptionsSheet.ShareOption
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            action()
        }) {
            VStack(spacing: Theme.Spacing.sm) {
                Image(systemName: option.icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(isSelected ? Theme.Colors.primary : Theme.Colors.textTertiary)
                    .frame(width: 48, height: 48)
                    .background(isSelected ? Theme.Colors.primary.opacity(0.12) : Theme.Colors.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small, style: .continuous))

                Text(option.title)
                    .font(Theme.Fonts.label(11))
                    .foregroundStyle(isSelected ? Theme.Colors.primary : Theme.Colors.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.sm)
            .background(isSelected ? Theme.Colors.primary.opacity(0.06) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                    .stroke(isSelected ? Theme.Colors.primary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Shareable Score Card

struct ShareableScoreCard: View {
    let score: Int
    let goodCount: Int
    let totalCount: Int
    let timeframe: String

    private var scoreColor: Color {
        switch score {
        case 80...100: return Theme.Colors.good
        case 60..<80: return Theme.Colors.fiber
        case 40..<60: return Theme.Colors.hard
        default: return Theme.Colors.blood
        }
    }

    private var scoreLabel: String {
        switch score {
        case 80...100: return "Excellent"
        case 60..<80: return "Good"
        case 40..<60: return "Fair"
        default: return "Needs Work"
        }
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: Date())
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    MascotCircle(size: 36)
                    Text("Pooply")
                        .font(Theme.Fonts.heading())
                        .foregroundStyle(Theme.Colors.textPrimary)
                }

                Spacer()

                Text(timeframe)
                    .font(Theme.Fonts.caption())
                    .foregroundStyle(Theme.Colors.textTertiary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Theme.Colors.backgroundSecondary)
                    .clipShape(Capsule())
            }

            // Score display
            ZStack {
                // Arc background
                ArcShape(startAngle: .degrees(-210), endAngle: .degrees(30))
                    .stroke(scoreColor.opacity(0.2), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 120, height: 120)

                // Arc progress
                ArcShape(startAngle: .degrees(-210), endAngle: .degrees(-210 + 240 * (Double(score) / 100)))
                    .stroke(scoreColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 120, height: 120)

                // Score text
                VStack(spacing: 2) {
                    HStack(alignment: .top, spacing: 2) {
                        Text("\(score)")
                            .font(Theme.Fonts.hero(44))
                            .foregroundStyle(Theme.Colors.textPrimary)

                        Text("%")
                            .font(Theme.Fonts.title(18))
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .offset(y: 6)
                    }

                    Text(scoreLabel)
                        .font(Theme.Fonts.captionBold())
                        .foregroundStyle(scoreColor)
                }
            }
            .frame(height: 140)

            // Stats row
            HStack(spacing: Theme.Spacing.md) {
                ShareStatItem(value: "\(goodCount)", label: "Good Logs", color: Theme.Colors.good)
                ShareStatItem(value: "\(totalCount)", label: "Total Logs", color: Theme.Colors.primary)
                ShareStatItem(
                    value: totalCount > 0 ? "\(Int((Double(goodCount) / Double(totalCount)) * 100))%" : "0%",
                    label: "Success Rate",
                    color: Theme.Colors.fiber
                )
            }

            // Footer
            HStack {
                Text(dateString)
                    .font(Theme.Fonts.micro())
                    .foregroundStyle(Theme.Colors.textTertiary)

                Spacer()

                Text("pooply.app")
                    .font(Theme.Fonts.micro())
                    .foregroundStyle(Theme.Colors.primary)
            }
        }
        .padding(Theme.Spacing.cardPadding)
        .background(Theme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.large, style: .continuous))
        .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
    }
}

// MARK: - Shareable Progress Card

struct ShareableProgressCard: View {
    let timeframe: String
    let logHistory: [Log]
    let calculateScore: (Log) -> Int

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: Date())
    }

    private var isWeekly: Bool {
        timeframe == "Today" || timeframe == "This Week"
    }

    private var dayCount: Int {
        isWeekly ? 7 : 30
    }

    /// Returns an array of (dayLabel, averageScore) for each day in the range
    private var dailyScores: [(label: String, score: Int?)] {
        let calendar = Calendar.current
        let now = Date()
        var results: [(String, Int?)] = []

        for i in stride(from: dayCount - 1, through: 0, by: -1) {
            guard let date = calendar.date(byAdding: .day, value: -i, to: now) else { continue }
            let logsForDay = logHistory.filter { calendar.isDate($0.timestamp, inSameDayAs: date) }

            let formatter = DateFormatter()
            if isWeekly {
                formatter.dateFormat = "EEE"
            } else {
                formatter.dateFormat = "d"
            }
            let label = formatter.string(from: date)

            if logsForDay.isEmpty {
                results.append((label, nil))
            } else {
                let avg = logsForDay.reduce(0) { $0 + calculateScore($1) } / logsForDay.count
                results.append((label, avg))
            }
        }

        return results
    }

    private var validScores: [Int] {
        dailyScores.compactMap { $0.score }
    }

    private var averageScore: Int {
        guard !validScores.isEmpty else { return 0 }
        return validScores.reduce(0, +) / validScores.count
    }

    private var bestScore: Int {
        validScores.max() ?? 0
    }

    private var totalLogs: Int {
        let calendar = Calendar.current
        let now = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -(dayCount - 1), to: now) else { return 0 }
        return logHistory.filter { $0.timestamp >= calendar.startOfDay(for: startDate) }.count
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    MascotCircle(size: 36)
                    Text("Pooply")
                        .font(Theme.Fonts.heading())
                        .foregroundStyle(Theme.Colors.textPrimary)
                }

                Spacer()

                Text(timeframe)
                    .font(Theme.Fonts.caption())
                    .foregroundStyle(Theme.Colors.textTertiary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Theme.Colors.backgroundSecondary)
                    .clipShape(Capsule())
            }

            // Line chart
            ProgressLineChart(
                dailyScores: dailyScores,
                isWeekly: isWeekly
            )
            .frame(height: 160)

            // Stats row
            HStack(spacing: Theme.Spacing.md) {
                ShareStatItem(value: "\(averageScore)", label: "Avg Score", color: Theme.Colors.primary)
                ShareStatItem(value: "\(bestScore)", label: "Best Score", color: Theme.Colors.good)
                ShareStatItem(value: "\(totalLogs)", label: "Total Logs", color: Theme.Colors.fiber)
            }

            // Footer
            HStack {
                Text(dateString)
                    .font(Theme.Fonts.micro())
                    .foregroundStyle(Theme.Colors.textTertiary)

                Spacer()

                Text("pooply.app")
                    .font(Theme.Fonts.micro())
                    .foregroundStyle(Theme.Colors.primary)
            }
        }
        .padding(Theme.Spacing.cardPadding)
        .background(Theme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.large, style: .continuous))
        .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
    }
}

// MARK: - Progress Line Chart

struct ProgressLineChart: View {
    let dailyScores: [(label: String, score: Int?)]
    let isWeekly: Bool

    private var maxLabelCount: Int {
        isWeekly ? 7 : 6
    }

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let chartHeight = height - 24 // Reserve space for labels
            let count = dailyScores.count
            guard count > 1 else { return AnyView(EmptyView()) }

            let stepX = width / CGFloat(count - 1)

            // Build points for non-nil scores
            let points: [(index: Int, point: CGPoint)] = dailyScores.enumerated().compactMap { (i, entry) in
                guard let score = entry.score else { return nil }
                let x = CGFloat(i) * stepX
                let y = chartHeight - (CGFloat(score) / 100.0 * chartHeight)
                return (i, CGPoint(x: x, y: y))
            }

            return AnyView(
                ZStack(alignment: .topLeading) {
                    // Horizontal guide lines
                    ForEach([0, 25, 50, 75, 100], id: \.self) { level in
                        let y = chartHeight - (CGFloat(level) / 100.0 * chartHeight)
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: width, y: y))
                        }
                        .stroke(Theme.Colors.textTertiary.opacity(0.15), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    }

                    if points.count >= 2 {
                        // Gradient fill under line
                        Path { path in
                            path.move(to: CGPoint(x: points.first!.point.x, y: chartHeight))
                            path.addLine(to: points.first!.point)

                            for i in 1..<points.count {
                                let prev = points[i - 1].point
                                let curr = points[i].point
                                let midX = (prev.x + curr.x) / 2
                                path.addCurve(to: curr,
                                              control1: CGPoint(x: midX, y: prev.y),
                                              control2: CGPoint(x: midX, y: curr.y))
                            }

                            path.addLine(to: CGPoint(x: points.last!.point.x, y: chartHeight))
                            path.closeSubpath()
                        }
                        .fill(
                            LinearGradient(
                                colors: [Theme.Colors.primary.opacity(0.3), Theme.Colors.primary.opacity(0.0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                        // Line
                        Path { path in
                            path.move(to: points.first!.point)
                            for i in 1..<points.count {
                                let prev = points[i - 1].point
                                let curr = points[i].point
                                let midX = (prev.x + curr.x) / 2
                                path.addCurve(to: curr,
                                              control1: CGPoint(x: midX, y: prev.y),
                                              control2: CGPoint(x: midX, y: curr.y))
                            }
                        }
                        .stroke(Theme.Colors.primary, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                    }

                    // Data points
                    ForEach(Array(points.enumerated()), id: \.offset) { _, entry in
                        Circle()
                            .fill(Theme.Colors.primary)
                            .frame(width: 6, height: 6)
                            .position(entry.point)
                    }

                    // X-axis labels
                    let labelStep = max(1, count / maxLabelCount)
                    ForEach(Array(stride(from: 0, to: count, by: labelStep)), id: \.self) { i in
                        Text(dailyScores[i].label)
                            .font(Theme.Fonts.micro())
                            .foregroundStyle(Theme.Colors.textTertiary)
                            .position(x: CGFloat(i) * stepX, y: height - 4)
                    }
                }
            )
        }
    }
}

// MARK: - Shareable Calendar Card

struct ShareableCalendarCard: View {
    let logHistory: [Log]
    let calculateScore: (Log) -> Int

    private var currentMonth: Date {
        let calendar = Calendar.current
        return calendar.date(from: calendar.dateComponents([.year, .month], from: Date()))!
    }

    private var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: Date())
    }

    private var weekdays: [String] {
        Calendar.current.shortWeekdaySymbols
    }

    /// Build array of day entries for the current month grid
    private var calendarDays: [CalendarDayEntry] {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: currentMonth)!
        let firstWeekday = calendar.component(.weekday, from: currentMonth) - 1 // 0-based

        var entries: [CalendarDayEntry] = []

        // Leading empty cells
        for _ in 0..<firstWeekday {
            entries.append(CalendarDayEntry(day: 0, status: .empty))
        }

        for day in range {
            guard let date = calendar.date(byAdding: .day, value: day - 1, to: currentMonth) else {
                entries.append(CalendarDayEntry(day: day, status: .noLog))
                continue
            }

            let logsForDay = logHistory.filter { calendar.isDate($0.timestamp, inSameDayAs: date) }

            if logsForDay.isEmpty {
                entries.append(CalendarDayEntry(day: day, status: .noLog))
            } else {
                let avgScore = logsForDay.reduce(0) { $0 + calculateScore($1) } / logsForDay.count
                if avgScore >= 70 {
                    entries.append(CalendarDayEntry(day: day, status: .good))
                } else if avgScore >= 40 {
                    entries.append(CalendarDayEntry(day: day, status: .okay))
                } else {
                    entries.append(CalendarDayEntry(day: day, status: .poor))
                }
            }
        }

        return entries
    }

    // Stats
    private var daysLogged: Int {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: currentMonth)!
        var count = 0
        for day in range {
            guard let date = calendar.date(byAdding: .day, value: day - 1, to: currentMonth) else { continue }
            if logHistory.contains(where: { calendar.isDate($0.timestamp, inSameDayAs: date) }) {
                count += 1
            }
        }
        return count
    }

    private var goodDaysPercent: Int {
        let goodCount = calendarDays.filter { $0.status == .good }.count
        guard daysLogged > 0 else { return 0 }
        return Int((Double(goodCount) / Double(daysLogged)) * 100)
    }

    private var currentStreak: Int {
        let calendar = Calendar.current
        let now = Date()
        var streak = 0
        var checkDate = now

        while true {
            let logsForDay = logHistory.filter { calendar.isDate($0.timestamp, inSameDayAs: checkDate) }
            if logsForDay.isEmpty { break }
            let avgScore = logsForDay.reduce(0) { $0 + calculateScore($1) } / logsForDay.count
            if avgScore >= 70 {
                streak += 1
            } else {
                break
            }
            guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prev
        }

        return streak
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    MascotCircle(size: 36)
                    Text("Pooply")
                        .font(Theme.Fonts.heading())
                        .foregroundStyle(Theme.Colors.textPrimary)
                }

                Spacer()

                Text(monthName)
                    .font(Theme.Fonts.caption())
                    .foregroundStyle(Theme.Colors.textTertiary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Theme.Colors.backgroundSecondary)
                    .clipShape(Capsule())
            }

            // Weekday headers
            HStack {
                ForEach(weekdays, id: \.self) { day in
                    Text(day.prefix(1).uppercased())
                        .font(Theme.Fonts.label(11))
                        .foregroundStyle(Theme.Colors.textTertiary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                ForEach(Array(calendarDays.enumerated()), id: \.offset) { _, entry in
                    if entry.status == .empty {
                        Color.clear.frame(height: 32)
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(entry.backgroundColor)
                                .frame(height: 32)

                            VStack(spacing: 1) {
                                Text("\(entry.day)")
                                    .font(Theme.Fonts.micro())
                                    .foregroundStyle(entry.textColor)

                                if entry.status != .noLog {
                                    Circle()
                                        .fill(entry.dotColor)
                                        .frame(width: 5, height: 5)
                                }
                            }
                        }
                    }
                }
            }

            // Stats row
            HStack(spacing: Theme.Spacing.md) {
                ShareStatItem(value: "\(daysLogged)", label: "Days Logged", color: Theme.Colors.primary)
                ShareStatItem(value: "\(goodDaysPercent)%", label: "Good Days", color: Theme.Colors.good)
                ShareStatItem(value: "\(currentStreak)", label: "Streak", color: Theme.Colors.fiber)
            }

            // Footer
            HStack {
                Text(dateString)
                    .font(Theme.Fonts.micro())
                    .foregroundStyle(Theme.Colors.textTertiary)

                Spacer()

                Text("pooply.app")
                    .font(Theme.Fonts.micro())
                    .foregroundStyle(Theme.Colors.primary)
            }
        }
        .padding(Theme.Spacing.cardPadding)
        .background(Theme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.large, style: .continuous))
        .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
    }
}

// MARK: - Calendar Day Entry

struct CalendarDayEntry {
    enum Status {
        case empty, noLog, good, okay, poor
    }

    let day: Int
    let status: Status

    var backgroundColor: Color {
        switch status {
        case .empty: return .clear
        case .noLog: return Theme.Colors.backgroundSecondary.opacity(0.5)
        case .good: return Theme.Colors.good.opacity(0.12)
        case .okay: return Theme.Colors.hard.opacity(0.12)
        case .poor: return Theme.Colors.blood.opacity(0.12)
        }
    }

    var textColor: Color {
        switch status {
        case .empty: return .clear
        case .noLog: return Theme.Colors.textTertiary
        case .good: return Theme.Colors.good
        case .okay: return Theme.Colors.hard
        case .poor: return Theme.Colors.blood
        }
    }

    var dotColor: Color {
        switch status {
        case .good: return Theme.Colors.good
        case .okay: return Theme.Colors.hard
        case .poor: return Theme.Colors.blood
        default: return .clear
        }
    }
}

// MARK: - Share Stat Item

struct ShareStatItem: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(Theme.Fonts.heading())
                .foregroundStyle(color)

            Text(label)
                .font(Theme.Fonts.label(9))
                .foregroundStyle(Theme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.sm)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small, style: .continuous))
    }
}

// MARK: - Timeframe Toggle

struct TimeframeToggle: View {
    @Binding var selected: String
    @Namespace private var animation
    private let options = ["TODAY", "WEEK", "MONTH"]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options, id: \.self) { option in
                Button(action: {
                    withAnimation(Theme.Animation.spring) {
                        selected = option
                    }
                }) {
                    Text(option)
                        .font(Theme.Fonts.label(12))
                        .foregroundStyle(selected == option ? Theme.Colors.textOnPrimary : Theme.Colors.textTertiary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background {
                            if selected == option {
                                Capsule()
                                    .fill(Theme.Colors.primary)
                                    .matchedGeometryEffect(id: "timeframe", in: animation)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Theme.Colors.backgroundSecondary)
        .clipShape(Capsule())
    }
}

// MARK: - Mini Stat Card

struct MiniStatCard: View {
    let value: Int
    let label: String
    let icon: String
    let color: Color
    var progress: CGFloat = 0
    var invertColor: Bool = false  // For blood - 0% is good

    private var displayColor: Color {
        if invertColor {
            return value == 0 ? Theme.Colors.good : color
        }
        return color
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(displayColor.opacity(0.2), lineWidth: 4)

                // Progress ring
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(displayColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                // Icon
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(displayColor.opacity(0.6))
            }
            .frame(width: 44, height: 44)

            VStack(spacing: 2) {
                Text("\(value)%")
                    .font(Theme.Fonts.heading(18))
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .contentTransition(.numericText())

                Text(label.uppercased())
                    .font(Theme.Fonts.label(9))
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

// MARK: - Streaks Row

struct StreaksRow: View {
    let currentStreak: Int
    let longestStreak: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Section Header
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.orange)
                Text("Streaks")
                    .font(Theme.Fonts.subheading())
                    .foregroundStyle(Theme.Colors.textPrimary)
            }

            // Streak Cards
            HStack(spacing: Theme.Spacing.sm) {
                StreakCard(
                    icon: "flame.fill",
                    value: currentStreak,
                    title: "Current",
                    subtitle: "day streak",
                    gradientColors: [Color.orange, Color.red],
                    tintColor: Color.orange
                )

                StreakCard(
                    icon: "trophy.fill",
                    value: longestStreak,
                    title: "Longest",
                    subtitle: "day streak",
                    gradientColors: [Color.yellow, Color.orange],
                    tintColor: Color.yellow
                )
            }
        }
    }
}

struct StreakCard: View {
    let icon: String
    let value: Int
    let title: String
    let subtitle: String
    let gradientColors: [Color]
    let tintColor: Color

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Icon with tinted background
            ZStack {
                Circle()
                    .fill(tintColor.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(
                        LinearGradient(colors: gradientColors, startPoint: .top, endPoint: .bottom)
                    )
            }

            // Value and labels
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(value)")
                    .font(Theme.Fonts.heading(24))
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .contentTransition(.numericText())

                VStack(alignment: .leading, spacing: 0) {
                    Text(title)
                        .font(Theme.Fonts.captionBold(12))
                        .foregroundStyle(Theme.Colors.textSecondary)

                    Text(subtitle)
                        .font(Theme.Fonts.micro())
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(Theme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous))
        .cardShadow()
    }
}

// MARK: - Calendar Card

struct CalendarCard: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @Binding var selectedMonth: Date
    @Binding var selectedDate: Date
    @Binding var showDayLogsModal: Bool

    private let weekdays = Calendar.current.shortWeekdaySymbols

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Month header
            HStack {
                Button(action: { monthUpdate(false) }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .frame(width: 32, height: 32)
                        .background(Theme.Colors.backgroundSecondary)
                        .clipShape(Circle())
                }

                Spacer()

                Text(monthYearString)
                    .font(Theme.Fonts.subheading())
                    .foregroundStyle(Theme.Colors.textPrimary)

                Spacer()

                Button(action: { monthUpdate(true) }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .frame(width: 32, height: 32)
                        .background(Theme.Colors.backgroundSecondary)
                        .clipShape(Circle())
                }
            }

            // Weekday labels
            HStack {
                ForEach(weekdays, id: \.self) { day in
                    Text(day.prefix(1).uppercased())
                        .font(Theme.Fonts.label(11))
                        .foregroundStyle(Theme.Colors.textTertiary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Days grid
            let days = extractDates(selectedMonth)
            LazyVGrid(columns: Array(repeating: GridItem(spacing: 8), count: 7), spacing: 8) {
                ForEach(days) { day in
                    if day.ignored {
                        Color.clear.frame(height: 46)
                    } else {
                        CalendarDayCell(
                            date: day.date,
                            isSelected: Calendar.current.isDate(day.date, inSameDayAs: selectedDate),
                            isToday: Calendar.current.isDateInToday(day.date),
                            category: userViewModel.dominantCategory(for: day.date)
                        ) {
                            selectedDate = day.date
                            showDayLogsModal = true
                        }
                    }
                }
            }
        }
        .padding(Theme.Spacing.cardPadding)
        .background(Theme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.large, style: .continuous))
        .cardShadow()
    }

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedMonth)
    }

    private func monthUpdate(_ increment: Bool) {
        let calendar = Calendar.current
        guard let month = calendar.date(byAdding: .month, value: increment ? 1 : -1, to: selectedMonth) else { return }
        withAnimation(Theme.Animation.spring) {
            selectedMonth = month
        }
    }
}

struct CalendarDayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let category: Log.PoopCategory?
    let action: () -> Void

    private var dayNumber: Int {
        Calendar.current.component(.day, from: date)
    }

    private var faceImage: String? {
        switch category {
        case .regular: return "goodFace"
        case .hard: return "hardFace"
        case .loose: return "looseFace"
        case nil: return nil
        }
    }

    private var categoryColor: Color {
        switch category {
        case .regular: return Theme.Colors.good
        case .hard: return Theme.Colors.hard
        case .loose: return Theme.Colors.loose
        case nil: return .clear
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                // Face IS the cell — no background
                ZStack {
                    if let face = faceImage {
                        Image(face)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 32, height: 32)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    } else {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(isToday ? Theme.Colors.primary.opacity(0.15) : Theme.Colors.backgroundSecondary.opacity(0.5))
                            .frame(width: 32, height: 32)
                    }

                    if isToday {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Theme.Colors.primary, lineWidth: 2)
                            .frame(width: 32, height: 32)
                    }
                }

                // Day number underneath
                Text("\(dayNumber)")
                    .font(Theme.Fonts.micro())
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(Theme.Animation.spring, value: isSelected)
    }
}

// MARK: - Recent Logs Section

struct RecentLogsSection: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @State private var logToEdit: Log?
    @State private var logToDelete: Log?
    @State private var logToViewPhoto: Log?
    @State private var showDeleteConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionHeader(title: "Recent Logs")

            if userViewModel.recentLogs.isEmpty {
                EmptyLogsView()
            } else {
                LazyVStack(spacing: Theme.Spacing.sm) {
                    ForEach(Array(userViewModel.recentLogs.prefix(5)), id: \.id) { log in
                        NewLogCard(
                            log: log,
                            score: userViewModel.calculatePoopScore(for: log),
                            onEdit: { logToEdit = log },
                            onDelete: {
                                logToDelete = log
                                showDeleteConfirmation = true
                            },
                            onViewPhoto: { logToViewPhoto = log }
                        )
                    }
                }
            }
        }
        .sheet(item: $logToEdit) { log in
            EditLogSheet(log: log, isPresented: Binding(
                get: { logToEdit != nil },
                set: { if !$0 { logToEdit = nil } }
            ))
            .environmentObject(userViewModel)
        }
        .fullScreenCover(item: $logToViewPhoto) { log in
            LogPhotoViewer(log: log)
        }
        .alert("Delete Log", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                logToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let log = logToDelete {
                    withAnimation {
                        userViewModel.deleteLog(log)
                    }
                }
                logToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete this log? This action cannot be undone.")
        }
    }
}

struct EmptyLogsView: View {
    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "doc.text")
                .font(.system(size: 32))
                .foregroundStyle(Theme.Colors.neutral)

            Text("No logs yet")
                .font(Theme.Fonts.body())
                .foregroundStyle(Theme.Colors.textTertiary)

            Text("Tap the + button to add your first log")
                .font(Theme.Fonts.caption())
                .foregroundStyle(Theme.Colors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.xl)
        .background(Theme.Colors.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous))
    }
}

// MARK: - New Log Card

struct NewLogCard: View {
    let log: Log
    let score: Int
    var onEdit: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    var onViewPhoto: (() -> Void)? = nil

    private var categoryColor: Color {
        switch log.poopScore {
        case .regular: return Theme.Colors.good
        case .hard: return Theme.Colors.hard
        case .loose: return Theme.Colors.loose
        }
    }

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: log.timestamp)
    }

    private var dayString: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(log.timestamp) {
            return "Today"
        } else if calendar.isDateInYesterday(log.timestamp) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: log.timestamp)
        }
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Poop type image
            Image(log.type.rawValue)
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text("\(dayString), \(timeString)")
                    .font(Theme.Fonts.captionBold())
                    .foregroundStyle(Theme.Colors.textPrimary)

                HStack(spacing: Theme.Spacing.sm) {
                    Text("Score: \(score)")
                        .font(Theme.Fonts.caption())
                        .foregroundStyle(Theme.Colors.textSecondary)

                    // Blood indicator
                    if log.bloodPercentage > 0 {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.Colors.blood)
                    }
                }
            }

            Spacer()

            // Category badge
            HStack(spacing: 4) {
                Text(log.poopScore.rawValue.capitalized)
                    .font(Theme.Fonts.label(11))
                    .foregroundStyle(categoryColor)

                Circle()
                    .fill(categoryColor)
                    .frame(width: 8, height: 8)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(categoryColor.opacity(0.12))
            .clipShape(Capsule())
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous))
        .cardShadow()
        .contentShape(Rectangle())
        .onTapGesture {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            if log.imageURL != nil, let onViewPhoto = onViewPhoto {
                onViewPhoto()
            } else {
                onEdit?()
            }
        }
        .contextMenu {
            if let onEdit = onEdit {
                Button {
                    onEdit()
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
            }

            if let onDelete = onDelete {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
}

// MARK: - Arc Shape

struct ArcShape: Shape {
    var startAngle: Angle
    var endAngle: Angle

    var animatableData: Double {
        get { endAngle.degrees }
        set { endAngle = .degrees(newValue) }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: rect.width / 2,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        return path
    }
}

// MARK: - Day Logs Modal

struct DayLogsModal: View {
    let selectedDate: Date
    @Binding var isPresented: Bool
    @EnvironmentObject var userViewModel: UserViewModel

    @State private var logToEdit: Log?
    @State private var logToDelete: Log?
    @State private var logToViewPhoto: Log?
    @State private var showDeleteConfirmation = false

    private var logsForSelectedDay: [Log] {
        let calendar = Calendar.current
        return userViewModel.logHistory
            .filter { calendar.isDate($0.timestamp, inSameDayAs: selectedDate) }
            .sorted { $0.timestamp > $1.timestamp }
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: selectedDate)
    }

    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    CloseButton(action: { isPresented = false })

                    Spacer()

                    Text(dateString)
                        .font(Theme.Fonts.subheading())
                        .foregroundStyle(Theme.Colors.textPrimary)

                    Spacer()

                    // Balance spacer
                    Color.clear.frame(width: 32, height: 32)
                }
                .padding()

                // Content
                if logsForSelectedDay.isEmpty {
                    Spacer()
                    VStack(spacing: Theme.Spacing.md) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 48))
                            .foregroundStyle(Theme.Colors.neutral)

                        Text("No logs")
                            .font(Theme.Fonts.heading())
                            .foregroundStyle(Theme.Colors.textPrimary)

                        Text("No entries recorded for this day")
                            .font(Theme.Fonts.body())
                            .foregroundStyle(Theme.Colors.textTertiary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: Theme.Spacing.sm) {
                            ForEach(logsForSelectedDay, id: \.id) { log in
                                NewLogCard(
                                    log: log,
                                    score: userViewModel.calculatePoopScore(for: log),
                                    onEdit: { logToEdit = log },
                                    onDelete: {
                                        logToDelete = log
                                        showDeleteConfirmation = true
                                    },
                                    onViewPhoto: { logToViewPhoto = log }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .sheet(item: $logToEdit) { log in
            EditLogSheet(log: log, isPresented: Binding(
                get: { logToEdit != nil },
                set: { if !$0 { logToEdit = nil } }
            ))
            .environmentObject(userViewModel)
        }
        .fullScreenCover(item: $logToViewPhoto) { log in
            LogPhotoViewer(log: log)
        }
        .alert("Delete Log", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                logToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let log = logToDelete {
                    withAnimation {
                        userViewModel.deleteLog(log)
                    }
                }
                logToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete this log? This action cannot be undone.")
        }
    }
}

// MARK: - Log Photo Viewer

struct LogPhotoViewer: View {
    let log: Log
    @Environment(\.dismiss) private var dismiss
    @State private var isRevealed = false

    private var scoreColor: Color {
        switch log.poopScore {
        case .regular: return Theme.Colors.good
        case .hard: return Theme.Colors.hard
        case .loose: return Theme.Colors.loose
        }
    }

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d 'at' h:mm a"
        return formatter.string(from: log.timestamp)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Photo
            if let urlString = log.imageURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .blur(radius: isRevealed ? 0 : 50)
                            .animation(.easeInOut(duration: 0.5), value: isRevealed)

                    case .failure:
                        VStack(spacing: Theme.Spacing.md) {
                            Image(systemName: "photo.badge.exclamationmark")
                                .font(.system(size: 48))
                                .foregroundStyle(.white.opacity(0.5))
                            Text("Failed to load photo")
                                .font(Theme.Fonts.body())
                                .foregroundStyle(.white.opacity(0.5))
                        }

                    case .empty:
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.5)

                    @unknown default:
                        EmptyView()
                    }
                }
            }

            // Reveal button
            if !isRevealed {
                Button {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        isRevealed = true
                    }
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                } label: {
                    Text("Tap to Reveal")
                        .font(Theme.Fonts.bodyBold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                }
            }

            // Top bar with close button
            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }

                    Spacer()

                    // Category badge
                    Text(log.poopScore.rawValue.capitalized)
                        .font(Theme.Fonts.label(12))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(scoreColor.opacity(0.8))
                        .clipShape(Capsule())
                }
                .padding(.horizontal, Theme.Spacing.screenHorizontal)
                .padding(.top, Theme.Spacing.md)

                Spacer()

                // Bottom info
                if isRevealed {
                    VStack(spacing: Theme.Spacing.sm) {
                        Text(timeString)
                            .font(Theme.Fonts.captionBold())
                            .foregroundStyle(.white)

                        Text("Score: \(UserViewModel.calculatePoopScoreStatic(for: log))")
                            .font(Theme.Fonts.caption())
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .padding(.bottom, Theme.Spacing.xxl)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
        }
    }
}

// MARK: - Edit Log Sheet

struct EditLogSheet: View {
    let log: Log
    @Binding var isPresented: Bool
    @EnvironmentObject var userViewModel: UserViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedType: Log.PoopType
    @State private var selectedColor: Log.PoopColor
    @State private var selectedSize: Log.PoopSize
    @State private var containsBlood: Bool
    @State private var timestamp: Date

    private let allTypes: [Log.PoopType] = Log.PoopType.allCases
    private let allColors: [Log.PoopColor] = [.lightBrown, .mediumBrown, .darkBrown, .green, .yellow, .black, .red]
    private let allSizes: [Log.PoopSize] = [.small, .medium, .large]

    init(log: Log, isPresented: Binding<Bool>) {
        self.log = log
        self._isPresented = isPresented
        self._selectedType = State(initialValue: log.type)
        self._selectedColor = State(initialValue: log.color)
        self._selectedSize = State(initialValue: log.size)
        self._containsBlood = State(initialValue: log.bloodPercentage > 0)
        self._timestamp = State(initialValue: log.timestamp)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    // Type Section
                    EditSectionCard {
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            EditSectionLabel(text: "Type", icon: "list.bullet")

                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 10),
                                GridItem(.flexible(), spacing: 10),
                                GridItem(.flexible(), spacing: 10)
                            ], spacing: 10) {
                                ForEach(allTypes, id: \.self) { type in
                                    TypeButton(
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

                    // Color Section
                    EditSectionCard {
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            EditSectionLabel(text: "Color", icon: "paintpalette.fill")

                            HStack(spacing: 0) {
                                ForEach(allColors, id: \.self) { color in
                                    ColorButton(
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
                        }
                    }

                    // Size Section
                    EditSectionCard {
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            EditSectionLabel(text: "Size", icon: "circle.lefthalf.filled")

                            HStack(spacing: Theme.Spacing.sm) {
                                ForEach(allSizes, id: \.self) { size in
                                    SizeButton(
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

                    // Blood Toggle
                    EditSectionCard {
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
                        }
                    }

                    // Date/Time
                    EditSectionCard {
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            EditSectionLabel(text: "Date & Time", icon: "calendar")

                            DatePicker("", selection: $timestamp, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.compact)
                                .tint(Theme.Colors.primary)
                                .labelsHidden()
                        }
                    }

                    Spacer().frame(height: Theme.Spacing.xl)
                }
                .padding(.horizontal, Theme.Spacing.screenHorizontal)
                .padding(.top, Theme.Spacing.sm)
            }
            .background(Theme.Colors.background)
            .navigationTitle("Edit Log")
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

    private func saveLog() {
        let category = Log.categorizePoopType(selectedType)
        let hydration = hydrationForType(selectedType)
        let fiber = fiberForType(selectedType)

        let updatedLog = Log(
            id: log.id,
            poopScore: category,
            type: selectedType,
            color: selectedColor,
            size: selectedSize,
            bloodPercentage: containsBlood ? 1.0 : 0.0,
            hydrationPercentage: hydration,
            fiberPercentage: fiber,
            timestamp: timestamp,
            analysis: log.analysis,
            imageURL: log.imageURL,
            isManualEntry: log.isManualEntry
        )

        userViewModel.updateLog(updatedLog)
        Task { try? await FirebaseService.shared.updateLog(updatedLog) }
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)
        dismiss()
    }

    private func hydrationForType(_ type: Log.PoopType) -> Double {
        switch type {
        case .separateHardLumps: return 0.2
        case .lumpySausage: return 0.4
        case .crackedSausage: return 0.7
        case .smoothSausage: return 0.9
        case .softBlobs: return 0.85
        case .fluffyPieces: return 0.5
        case .watery: return 0.3
        }
    }

    private func fiberForType(_ type: Log.PoopType) -> Double {
        switch type {
        case .separateHardLumps: return 0.2
        case .lumpySausage: return 0.4
        case .crackedSausage: return 0.8
        case .smoothSausage: return 0.95
        case .softBlobs: return 0.7
        case .fluffyPieces: return 0.3
        case .watery: return 0.2
        }
    }
}

// MARK: - Edit Section Card Container

private struct EditSectionCard<Content: View>: View {
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

// MARK: - Edit Section Label with Icon

private struct EditSectionLabel: View {
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

// Helper button views for EditLogSheet
private struct TypeButton: View {
    let type: Log.PoopType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            action()
        }) {
            VStack(spacing: 6) {
                Image(type.rawValue)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)

                Text("Type \(typeNumber)")
                    .font(Theme.Fonts.micro())
                    .foregroundStyle(isSelected ? Theme.Colors.primary : Theme.Colors.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Theme.Colors.primary.opacity(0.1) : Theme.Colors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.small)
                    .stroke(isSelected ? Theme.Colors.primary : Color.clear, lineWidth: 2)
            )
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
}

private struct ColorButton: View {
    let poopColor: Log.PoopColor
    let isSelected: Bool
    let action: () -> Void

    private var displayColor: Color {
        switch poopColor {
        case .lightBrown: return Color(red: 0.76, green: 0.60, blue: 0.42)
        case .mediumBrown: return Color(red: 0.55, green: 0.35, blue: 0.17)
        case .darkBrown: return Color(red: 0.36, green: 0.20, blue: 0.09)
        case .green: return Color(red: 0.30, green: 0.50, blue: 0.25)
        case .yellow: return Color(red: 0.85, green: 0.75, blue: 0.35)
        case .black: return Color(red: 0.15, green: 0.12, blue: 0.10)
        case .red: return Color(red: 0.70, green: 0.20, blue: 0.20)
        }
    }

    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            action()
        }) {
            Circle()
                .fill(displayColor)
                .frame(width: 44, height: 44)
                .overlay(
                    Circle()
                        .stroke(isSelected ? Theme.Colors.primary : Color.clear, lineWidth: 3)
                        .padding(2)
                )
                .overlay(
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .opacity(isSelected ? 1 : 0)
                )
        }
    }
}

private struct SizeButton: View {
    let size: Log.PoopSize
    let isSelected: Bool
    let action: () -> Void

    private var label: String {
        switch size {
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        }
    }

    private var icon: String {
        switch size {
        case .small: return "circle.fill"
        case .medium: return "circle.fill"
        case .large: return "circle.fill"
        }
    }

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
                Image(systemName: icon)
                    .font(.system(size: iconSize))
                    .foregroundStyle(isSelected ? Theme.Colors.primary : Theme.Colors.textTertiary)

                Text(label)
                    .font(Theme.Fonts.caption())
                    .foregroundStyle(isSelected ? Theme.Colors.primary : Theme.Colors.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? Theme.Colors.primary.opacity(0.1) : Theme.Colors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.small)
                    .stroke(isSelected ? Theme.Colors.primary : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - Preview

#Preview {
    HomeView(
        showCameraView: .constant(false),
        showManualEntry: .constant(false),
        showProfileModal: .constant(false)
    )
    .environmentObject(
        UserViewModel(
            user: User(name: "Jessica", age: 25, weight: 160, gender: "female"),
            withDummyData: true
        )
    )
}
