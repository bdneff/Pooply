//
//  HomeView.swift
//  Pooply
//
//  Home — v5 Tiimo-minimal, restructured:
//  - Last 7 day-rings ABOVE the score
//  - Big Poop Score; label + trend chip tight underneath
//  - Slim plain-text Last Log line (no card)
//  - Green Zone section Duolingo-style: stat sub-boxes + calendar (no logs inside)
//  - Selected day LogCards rendered separately under the calendar
//

import SwiftUI
import FirebaseAnalytics

struct HomeView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @Binding var showProfile: Bool
    @Binding var showLogOptions: Bool

    @State private var scoreAppeared: Bool = false
    @State private var selectedMonth: Date = .currentMonth
    @State private var dayLogsModalDate: Date?

    private var score: Int { userViewModel.rollingPoopScore7Day }
    private var delta: Int { userViewModel.poopScoreDelta7Day }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {

                topBar
                    .padding(.horizontal, Theme.Spacing.screenHorizontal)
                    .padding(.top, 4)

                Last7DayStrip(userVM: userViewModel)
                    .padding(.horizontal, Theme.Spacing.screenHorizontal)
                    .padding(.top, 16)

                heroScore
                    .padding(.top, 8)
                    .padding(.bottom, 28)

                // Green Zone + Calendar (tap day → modal)
                GreenZoneCalendarCard(
                    userVM: userViewModel,
                    selectedMonth: $selectedMonth,
                    onDayTap: { date in
                        dayLogsModalDate = date
                    }
                )
                .padding(.horizontal, Theme.Spacing.screenHorizontal)

                // Recent Logs (last 3)
                RecentLogsSection(userVM: userViewModel)
                    .padding(.horizontal, Theme.Spacing.screenHorizontal)
                    .padding(.top, 20)

                Spacer().frame(height: 120)
            }
        }
        .onAppear {
            scoreAppeared = true
            Analytics.logEvent("home_viewed", parameters: nil)
        }
        .sheet(item: Binding(
            get: { dayLogsModalDate.map { DayLogsIdentifier(date: $0) } },
            set: { dayLogsModalDate = $0?.date }
        )) { ident in
            DayLogsModal(date: ident.date, userVM: userViewModel)
                .presentationBackground(.clear)
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack(alignment: .top) {
            Text("Pooply")
                .font(Theme.Fonts.title(28))
                .foregroundStyle(Theme.Colors.espresso)
                .padding(.top, 6)

            Spacer()

            MascotAvatar(size: 52) { showProfile = true }
        }
    }

    // MARK: - Hero (number, then label + delta chip tight below)

    private var heroScore: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topTrailing) {
                Text("\(score)")
                    .font(Theme.Fonts.hero(130))
                    .foregroundStyle(Theme.Colors.espresso)
                    .contentTransition(.numericText())
                    .scaleEffect(scoreAppeared ? 1.0 : 0.85)
                    .opacity(scoreAppeared ? 1.0 : 0.0)
                    .animation(.spring(response: 0.7, dampingFraction: 0.62).delay(0.1), value: scoreAppeared)

                if delta != 0 {
                    deltaIndicator
                        .offset(x: 18, y: 14)
                        .scaleEffect(scoreAppeared ? 1.0 : 0.3)
                        .opacity(scoreAppeared ? 1.0 : 0.0)
                        .animation(.spring(response: 0.55, dampingFraction: 0.6).delay(0.45), value: scoreAppeared)
                }
            }

            VStack(spacing: 10) {
                Text("POOP SCORE")
                    .font(Theme.Fonts.label(12))
                    .tracking(1.5)
                    .foregroundStyle(Theme.Colors.espressoLight)

                if userViewModel.lastLog != nil {
                    HStack(spacing: 5) {
                        Image(systemName: "clock")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Theme.Colors.espressoLight)
                        Text("Last log: \(userViewModel.timeSinceLastPoopString)")
                            .font(Theme.Fonts.caption(12))
                            .foregroundStyle(Theme.Colors.espressoLight)
                    }
                } else {
                    // First-launch hint — gives the screen a job when there's no data yet.
                    HStack(spacing: 5) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Theme.Colors.espressoLight)
                        Text("Tap + to log your first poop")
                            .font(Theme.Fonts.caption(12))
                            .foregroundStyle(Theme.Colors.espressoLight)
                    }
                }
            }
            .padding(.top, -6)  // pull label a little closer to the number
        }
    }

    private var deltaIndicator: some View {
        let isUp = delta >= 0
        let color = isUp ? Theme.Colors.dataGreen : Theme.Colors.dataPink
        return HStack(spacing: 3) {
            Image(systemName: isUp ? "arrow.up.right" : "arrow.down.right")
                .font(.system(size: 10, weight: .bold))
            Text("\(isUp ? "+" : "")\(delta)")
                .font(Theme.Fonts.captionBold(13))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(color.opacity(0.16)))
        .overlay(Capsule().stroke(color.opacity(0.25), lineWidth: 0.5))
    }
}

// MARK: - Last 7 day-rings strip

struct Last7DayStrip: View {
    let userVM: UserViewModel

    fileprivate struct DayDot: Identifiable {
        let id = UUID()
        let date: Date
        let weekday: String
        let dayNum: String
        let status: Status
        let isToday: Bool

        enum Status {
            case greenZone
            case mixed
            case noLog
        }
    }

    private var days: [DayDot] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let weekdayFmt = DateFormatter()
        weekdayFmt.dateFormat = "EEEEE"
        let dayFmt = DateFormatter()
        dayFmt.dateFormat = "d"

        return (0..<7).map { offset -> DayDot in
            let date = cal.date(byAdding: .day, value: -(6 - offset), to: today)!
            let logs = userVM.logHistory.filter { cal.isDate($0.timestamp, inSameDayAs: date) }
            let status: DayDot.Status = {
                if logs.isEmpty { return .noLog }
                return userVM.isGreenZoneDay(date) ? .greenZone : .mixed
            }()
            return DayDot(
                date: date,
                weekday: weekdayFmt.string(from: date),
                dayNum: dayFmt.string(from: date),
                status: status,
                isToday: cal.isDateInToday(date)
            )
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(days) { day in
                VStack(spacing: 6) {
                    Text(day.weekday)
                        .font(Theme.Fonts.label(10))
                        .tracking(0.3)
                        .foregroundStyle(Theme.Colors.espressoLight)

                    ZStack {
                        ringFor(day)
                        Text(day.dayNum)
                            .font(Theme.Fonts.captionBold(13))
                            .foregroundStyle(textColor(for: day))
                    }
                    .frame(width: 36, height: 36)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    @ViewBuilder
    fileprivate func ringFor(_ day: DayDot) -> some View {
        if day.isToday {
            Circle().strokeBorder(Theme.Colors.espresso, lineWidth: 2.5)
        } else {
            switch day.status {
            case .greenZone:
                Circle().strokeBorder(Theme.Colors.dataGreen, lineWidth: 2.5)
            case .mixed:
                Circle().strokeBorder(Theme.Colors.dataPink, lineWidth: 2.5)
            case .noLog:
                Circle().strokeBorder(
                    Theme.Colors.espressoLight.opacity(0.35),
                    style: StrokeStyle(lineWidth: 1.5, dash: [3, 3])
                )
            }
        }
    }

    private func textColor(for day: DayDot) -> Color {
        if day.isToday { return Theme.Colors.espresso }
        switch day.status {
        case .greenZone, .mixed: return Theme.Colors.espresso
        case .noLog:             return Theme.Colors.espressoLight.opacity(0.6)
        }
    }
}

// MARK: - Last Logged plain-text line (no card)

/// Last Log card — LogCard-style with a small "LAST LOG · 11h ago" header on top.
struct LastLoggedLine: View {
    let log: Log?
    let timeAgo: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header row: clock icon + LAST LOG · time ago
            HStack(spacing: 6) {
                Image(systemName: "clock")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.Colors.espressoLight)
                Text("LAST LOG")
                    .font(Theme.Fonts.label(10))
                    .tracking(1.3)
                    .foregroundStyle(Theme.Colors.espressoLight)
                if log != nil {
                    Text("·")
                        .foregroundStyle(Theme.Colors.espressoLight)
                    Text(timeAgo)
                        .font(Theme.Fonts.captionBold(12))
                        .foregroundStyle(Theme.Colors.espresso)
                }
                Spacer()
            }

            if let log {
                // LogCard-style body wrapped in a thin gray border to differentiate from outer card
                let s = UserViewModel.calculatePoopScoreStatic(for: log)
                let band = scoreBandColor(s)
                HStack(spacing: Theme.Spacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: Theme.Radius.small, style: .continuous)
                            .fill(band.opacity(0.18))
                        Image(log.type.rawValue)
                            .resizable()
                            .scaledToFit()
                            .padding(8)
                    }
                    .frame(width: 48, height: 48)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(timeString(log.timestamp))
                            .font(Theme.Fonts.bodyBold(14))
                            .foregroundStyle(Theme.Colors.espresso)
                        Text(dayString(log.timestamp))
                            .font(Theme.Fonts.caption(12))
                            .foregroundStyle(Theme.Colors.espressoLight)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text("\(s)")
                                .font(Theme.Fonts.bodyBold(18))
                                .foregroundStyle(Theme.Colors.espresso)
                            Text("/100")
                                .font(Theme.Fonts.caption(10))
                                .foregroundStyle(Theme.Colors.espressoLight)
                        }
                        ScoreBar(score: s, width: 56)
                    }
                }
                .padding(Theme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Theme.Colors.espressoLight.opacity(0.28), lineWidth: 1)
                )
            } else {
                Text("No logs yet")
                    .font(Theme.Fonts.bodyBold(15))
                    .foregroundStyle(Theme.Colors.espressoMid)
                    .padding(.vertical, 6)
            }
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassSurface(radius: Theme.Radius.large)
    }

    private func timeString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: date).lowercased()
    }

    private func dayString(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date)     { return "Today" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f.string(from: date)
    }
}

/// Score → color band. Reused across LogCard and last log line.
func scoreBandColor(_ score: Int) -> Color {
    if score >= 70 { return Theme.Colors.dataGreen }
    if score >= 40 { return Theme.Colors.dataYellow }
    return Theme.Colors.dataPink
}

/// Proportional score bar — gray track + colored fill = score percent.
struct ScoreBar: View {
    let score: Int
    var width: CGFloat = 56
    var height: CGFloat = 4

    var body: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(Theme.Colors.neutral200.opacity(0.6))
                .frame(width: width, height: height)
            Capsule()
                .fill(scoreBandColor(score))
                .frame(width: width * CGFloat(max(0, min(100, score))) / 100, height: height)
        }
    }
}

// MARK: - Green Zone Calendar Card (Duolingo-style: stat boxes + calendar only)

struct GreenZoneCalendarCard: View {
    @ObservedObject var userVM: UserViewModel
    @Binding var selectedMonth: Date
    let onDayTap: (Date) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Inline header — small leaf + GREEN ZONE on top line, "N day streak" below. % far right.
            HStack(alignment: .top, spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        GreenZoneLeaf(size: 16)
                        Text("GREEN ZONE")
                            .font(Theme.Fonts.label(11))
                            .tracking(1.3)
                            .foregroundStyle(Theme.Colors.espressoLight)
                    }
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text("\(userVM.greenZoneStreak)")
                            .font(Theme.Fonts.hero(28))
                            .foregroundStyle(Theme.Colors.espresso)
                            .contentTransition(.numericText())
                        Text("day streak")
                            .font(Theme.Fonts.bodyBold(13))
                            .foregroundStyle(Theme.Colors.espressoMid)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Text("\(userVM.greenZone30DayPercentage)%")
                        .font(Theme.Fonts.hero(22))
                        .foregroundStyle(Theme.Colors.dataGreen)
                        .contentTransition(.numericText())
                    Text("THIS MONTH")
                        .font(Theme.Fonts.label(9))
                        .tracking(1.0)
                        .foregroundStyle(Theme.Colors.espressoLight)
                }
            }

            // Month navigator
            HStack {
                Button { previousMonth() } label: { chevron("chevron.left") }
                Spacer()
                Text(monthTitle)
                    .font(Theme.Fonts.label(11))
                    .tracking(1.5)
                    .foregroundStyle(Theme.Colors.espresso)
                    .textCase(.uppercase)
                Spacer()
                Button { nextMonth() } label: { chevron("chevron.right") }
            }
            .padding(.top, 18)

            // Weekday labels
            HStack(spacing: 0) {
                ForEach(["S","M","T","W","T","F","S"], id: \.self) { l in
                    Text(l)
                        .font(Theme.Fonts.label(9))
                        .foregroundStyle(Theme.Colors.espressoLight.opacity(0.7))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 12)

            // Calendar grid
            let days = monthDays(for: selectedMonth)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 6) {
                ForEach(Array(days.enumerated()), id: \.element.id) { idx, day in
                    let isGreen = !day.ignored && userVM.isGreenZoneDay(day.date)
                    let leftConnected = isGreen && idx > 0
                        && !days[idx - 1].ignored
                        && userVM.isGreenZoneDay(days[idx - 1].date)
                    let rightConnected = isGreen && idx < days.count - 1
                        && !days[idx + 1].ignored
                        && userVM.isGreenZoneDay(days[idx + 1].date)
                    GreenZoneCalendarDayCell(
                        date: day.date,
                        isIgnored: day.ignored,
                        isGreenZone: isGreen,
                        hasLogs: userVM.dayHasLogs(day.date),
                        leftConnected: leftConnected,
                        rightConnected: rightConnected,
                        isSelected: false,
                        onTap: {
                            guard !day.ignored else { return }
                            Theme.Haptics.light()
                            onDayTap(day.date)
                        }
                    )
                }
            }
            .padding(.top, 6)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .glassSurface(radius: Theme.Radius.large)
    }

    private var monthTitle: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: selectedMonth)
    }

    private func previousMonth() {
        Theme.Haptics.light()
        if let m = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) {
            withAnimation(Theme.Animation.spring) { selectedMonth = m }
        }
    }

    private func nextMonth() {
        Theme.Haptics.light()
        if let m = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) {
            withAnimation(Theme.Animation.spring) { selectedMonth = m }
        }
    }

    private func chevron(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(Theme.Colors.espresso)
            .frame(width: 26, height: 26)
            .background(Circle().fill(Color.white.opacity(0.55)))
            .overlay(Circle().stroke(Color.white.opacity(0.6), lineWidth: 1))
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

// MARK: - Stat Mini Box (Duolingo-style stat container)

struct StatMiniBox: View {
    let iconBuilder: () -> AnyView
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 10) {
            iconBuilder()
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(Theme.Fonts.bodyBold(15))
                    .foregroundStyle(Theme.Colors.espresso)
                    .contentTransition(.numericText())
                Text(label)
                    .font(Theme.Fonts.caption(11))
                    .foregroundStyle(Theme.Colors.espressoLight)
            }
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.55))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.6), lineWidth: 1)
                )
        )
    }
}

// MARK: - Calendar day cell — Duolingo pill style

private struct GreenZoneCalendarDayCell: View {
    let date: Date
    let isIgnored: Bool
    let isGreenZone: Bool
    let hasLogs: Bool
    let leftConnected: Bool
    let rightConnected: Bool
    let isSelected: Bool
    let onTap: () -> Void

    private var dayNum: String {
        let f = DateFormatter(); f.dateFormat = "d"
        return f.string(from: date)
    }

    private var corners: (lead: CGFloat, trail: CGFloat) {
        let r: CGFloat = 16
        return (leftConnected ? 0 : r, rightConnected ? 0 : r)
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    private var numberColor: Color {
        if isIgnored { return Theme.Colors.espressoLight.opacity(0.4) }
        if isToday && isGreenZone { return .white }
        return Theme.Colors.espresso
    }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Light green streak pill bg (non-today green days)
                if isGreenZone && !isToday {
                    UnevenRoundedRectangle(
                        topLeadingRadius: corners.lead,
                        bottomLeadingRadius: corners.lead,
                        bottomTrailingRadius: corners.trail,
                        topTrailingRadius: corners.trail,
                        style: .continuous
                    )
                    .fill(Theme.Colors.dataGreen.opacity(0.28))
                    .frame(height: 32)
                    .padding(.leading, leftConnected ? 0 : 3)
                    .padding(.trailing, rightConnected ? 0 : 3)
                }

                // Today: solid green fill if also green zone
                if isToday && isGreenZone {
                    Circle()
                        .fill(Theme.Colors.dataGreen)
                        .frame(width: 32, height: 32)
                }

                // Today: ALWAYS a black ring (sits on top of fill if any)
                if isToday && !isIgnored {
                    Circle()
                        .strokeBorder(Theme.Colors.espresso, lineWidth: 2)
                        .frame(width: 32, height: 32)
                }

                // Selected non-today indicator
                if isSelected && !isToday {
                    Circle()
                        .strokeBorder(Theme.Colors.espresso, lineWidth: 1.5)
                        .frame(width: 32, height: 32)
                }

                Text(dayNum)
                    .font(Theme.Fonts.captionBold(11))
                    .foregroundStyle(numberColor)
            }
            // Fixed row height so months with sparse data don't collapse —
            // matches the 32pt pill/circle so dense and empty months align.
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isIgnored)
    }
}

// MARK: - Recent Logs (last 3 LogCards across all time)

struct RecentLogsSection: View {
    let userVM: UserViewModel

    private var logs: [Log] {
        Array(userVM.logHistory.sorted { $0.timestamp > $1.timestamp }.prefix(3))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Recent Logs")
                    .font(Theme.Fonts.heading(18))
                    .foregroundStyle(Theme.Colors.espresso)
                Spacer()
            }

            if logs.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Theme.Colors.espressoLight)
                    Text("Your first log will show up here")
                        .font(Theme.Fonts.caption(13))
                        .foregroundStyle(Theme.Colors.espressoLight)
                    Spacer()
                }
                .padding(.vertical, 8)
            } else {
                VStack(spacing: 10) {
                    ForEach(logs) { log in
                        LogCard(log: log)
                    }
                }
            }
        }
    }
}

// MARK: - Day Logs Modal (opened by tapping a calendar day)

struct DayLogsIdentifier: Identifiable {
    let date: Date
    var id: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}

struct DayLogsModal: View {
    let date: Date
    let userVM: UserViewModel

    private var logs: [Log] {
        let cal = Calendar.current
        return userVM.logHistory
            .filter { cal.isDate($0.timestamp, inSameDayAs: date) }
            .sorted { $0.timestamp > $1.timestamp }
    }

    private var dateTitle: String {
        let cal = Calendar.current
        if cal.isDateInToday(date)     { return "Today" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f.string(from: date)
    }

    var body: some View {
        ZStack {
            FrostedSheetBackground()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("LOGS")
                            .font(Theme.Fonts.label(10))
                            .tracking(1.5)
                            .foregroundStyle(Theme.Colors.espressoLight)
                        Text(dateTitle)
                            .font(Theme.Fonts.title(26))
                            .foregroundStyle(Theme.Colors.espresso)
                    }
                    .padding(.top, Theme.Spacing.md)

                    if logs.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Theme.Colors.espressoLight)
                            Text("No logs recorded this day")
                                .font(Theme.Fonts.caption(13))
                                .foregroundStyle(Theme.Colors.espressoLight)
                            Spacer()
                        }
                        .padding(.vertical, 10)
                    } else {
                        VStack(spacing: 10) {
                            ForEach(logs) { log in
                                LogCard(log: log)
                            }
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

// MARK: - Preview

#Preview {
    ZStack {
        CreamBackground()
        HomeView(
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
