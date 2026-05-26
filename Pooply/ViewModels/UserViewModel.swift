//
//  UserViewModel.swift
//  Pooply
//
//  Created by Brandon Grossnickle on 9/19/25.
//

import Foundation
import SwiftUI

class UserViewModel: ObservableObject {
    @Published var user: User
    @Published var logHistory: [Log] = []

    init(user: User, withDummyData: Bool = false) {
        self.user = user
        // ⚠️ SCREENSHOT MODE — when `withDummyData` is true the saved logs are
        // replaced in-memory with the dummy improvement-arc dataset. Dummy
        // logs are NOT written back to UserDefaults, so killing the app and
        // flipping the flag off restores the user's real data untouched.
        // FLIP THIS OFF (set `withDummyData: false` at the call sites in
        // PooplyApp.swift) BEFORE the App Store build.
        if withDummyData {
            self.logHistory = Log.generateDummyData(count: 30)
        } else {
            self.logHistory = UserDefaultsService.shared.loadLogs()
        }
    }
    
    // Current regular streak
    var regularStreak: Int {
        var streak = 0
        let sortedLogs = logHistory.sorted { $0.timestamp > $1.timestamp }

        for log in sortedLogs {
            if log.poopScore == .regular { streak += 1 } else { break }
        }
        return streak
    }

    // Longest regular streak
    var longestRegularStreak: Int {
        let sortedLogs = logHistory.sorted { $0.timestamp < $1.timestamp }
        var currentStreak = 0
        var maxStreak = 0

        for log in sortedLogs {
            if log.poopScore == .regular {
                currentStreak += 1
                maxStreak = max(maxStreak, currentStreak)
            } else {
                currentStreak = 0
            }
        }
        return maxStreak
    }
    
    var recentLogs: [Log] {
        Array(logHistory.sorted(by: { $0.timestamp > $1.timestamp }).prefix(10))
    }

    var lastLog: Log? {
        logHistory.sorted(by: { $0.timestamp > $1.timestamp }).first
    }

    var timeBasedGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "Good Morning! ☀️"
        case 12..<17:
            return "Good Afternoon! ☀️"
        case 17..<22:
            return "Good Evening!🌙"
        default:
            return "Good Evening! 🌙"
        }
    }

    func lastLogDescription() -> String {
        guard let lastLog = lastLog else {
            return "No logs recorded yet."
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let timeString = formatter.string(from: lastLog.timestamp).lowercased()

        let calendar = Calendar.current
        let dayDescription: String

        if calendar.isDateInToday(lastLog.timestamp) {
            dayDescription = "today"
        } else if calendar.isDateInYesterday(lastLog.timestamp) {
            dayDescription = "yesterday"
        } else {
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "EEEE"
            dayDescription = dayFormatter.string(from: lastLog.timestamp).lowercased()
        }

        return "Your last log at \(timeString) \(dayDescription) was: \(lastLog.poopScore.rawValue.capitalized)"
    }
    
    var weeklySummary: [String: (averageScore: Int, color: String)] {
        var dayCategories: [String: [Log.PoopCategory]] = [:]

        for log in logHistory {
            if log.timestamp.isDateInThisWeek() {
                let weekday = log.weekday // e.g. "Monday"
                dayCategories[weekday, default: []].append(log.poopScore)
            }
        }

        var result: [String: (Int, String)] = [:]
        for (day, categories) in dayCategories {
            // Calculate percentage of regular poops
            let regularCount = categories.filter { $0 == .regular }.count
            let percentage = Int(Double(regularCount) / Double(categories.count) * 100)

            let color: String
            switch percentage {
            case 70...100: color = "green"
            case 40..<70: color = "yellow"
            default: color = "red"
            }
            result[day] = (percentage, color)
        }

        return result
    }

    // Gut health percentage for timeframe
    func gutHealthPercentage(for timeframe: String) -> Double {
        let calendar = Calendar.current
        let now = Date()
        let filteredLogs: [Log]

        switch timeframe {
        case "TODAY":
            filteredLogs = logHistory.filter { calendar.isDateInToday($0.timestamp) }
        case "WEEK":
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: now)!
            filteredLogs = logHistory.filter { $0.timestamp >= weekAgo }
        case "MONTH":
            let monthAgo = calendar.date(byAdding: .month, value: -1, to: now)!
            filteredLogs = logHistory.filter { $0.timestamp >= monthAgo }
        default:
            filteredLogs = logHistory
        }

        guard !filteredLogs.isEmpty else { return 0 }

        let regularCount = filteredLogs.filter { $0.poopScore == .regular }.count
        return Double(regularCount) / Double(filteredLogs.count)
    }

    // Check if day has regular poops for calendar marking
    func dayHasRegularPoops(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let logsForDay = logHistory.filter { calendar.isDate($0.timestamp, inSameDayAs: date) }
        return logsForDay.contains { $0.poopScore == .regular }
    }

    /// Get the dominant poop category for a day (prioritizes worst)
    func dominantCategory(for date: Date) -> Log.PoopCategory? {
        let calendar = Calendar.current
        let logsForDay = logHistory.filter { calendar.isDate($0.timestamp, inSameDayAs: date) }
        guard !logsForDay.isEmpty else { return nil }

        let hardCount = logsForDay.filter { $0.poopScore == .hard }.count
        let looseCount = logsForDay.filter { $0.poopScore == .loose }.count
        let regularCount = logsForDay.filter { $0.poopScore == .regular }.count

        if hardCount >= looseCount && hardCount >= regularCount { return .hard }
        if looseCount >= regularCount { return .loose }
        return .regular
    }

    // MARK: - Poop Score Calculation (Multi-factor)

    /// Calculate poop score for a single log (0-100) - Static version for use without instance
    static func calculatePoopScoreStatic(for log: Log) -> Int {
        var score = 0

        // Bristol Type (40% weight)
        switch log.type {
        case .smoothSausage:        score += 40  // Type 4 - Ideal
        case .crackedSausage:       score += 36  // Type 3 - Great
        case .softBlobs:            score += 28  // Type 5 - Okay
        case .lumpySausage:         score += 20  // Type 2 - Mild constipation
        case .fluffyPieces:         score += 15  // Type 6 - Mild diarrhea
        case .separateHardLumps:    score += 10  // Type 1 - Constipated
        case .watery:               score += 5   // Type 7 - Diarrhea
        }

        // Color (25% weight)
        switch log.color {
        case .mediumBrown:  score += 25  // Ideal
        case .darkBrown:    score += 22
        case .lightBrown:   score += 20
        case .green:        score += 12  // Could indicate diet or bile
        case .yellow:       score += 10  // Could indicate fat malabsorption
        case .black:        score += 5   // Could indicate bleeding (alert)
        case .red:          score += 0   // Blood present (critical)
        }

        // Blood (20% weight) - Critical health factor
        if log.bloodPercentage == 0 {
            score += 20
        } else if log.bloodPercentage < 0.05 {
            score += 8  // Minor traces
        } else {
            score += 0  // Significant blood
        }

        // Size (15% weight)
        switch log.size {
        case .medium:   score += 15  // Ideal
        case .large:    score += 12
        case .small:    score += 8
        }

        return min(score, 100)  // Cap at 100
    }

    /// Calculate poop score for a single log (0-100) - Instance method
    func calculatePoopScore(for log: Log) -> Int {
        return UserViewModel.calculatePoopScoreStatic(for: log)
    }

    /// Average poop score for a timeframe (0-100)
    func averagePoopScore(for timeframe: String) -> Int {
        let logs = getLogsForTimeframe(timeframe)
        guard !logs.isEmpty else { return 0 }

        let totalScore = logs.reduce(0) { $0 + calculatePoopScore(for: $1) }
        return totalScore / logs.count
    }

    /// Count of "good" logs (score >= 70) in timeframe
    func goodLogCount(for timeframe: String) -> Int {
        let logs = getLogsForTimeframe(timeframe)
        return logs.filter { calculatePoopScore(for: $0) >= 70 }.count
    }

    /// Total log count for timeframe
    func totalLogCount(for timeframe: String) -> Int {
        return getLogsForTimeframe(timeframe).count
    }

    /// Check if day has any logs
    func dayHasLogs(_ date: Date) -> Bool {
        let calendar = Calendar.current
        return logHistory.contains { calendar.isDate($0.timestamp, inSameDayAs: date) }
    }

    /// Get log count for a specific day
    func logCountForDay(_ date: Date) -> Int {
        let calendar = Calendar.current
        return logHistory.filter { calendar.isDate($0.timestamp, inSameDayAs: date) }.count
    }

    /// Get category counts for a day
    func categoriesForDay(_ date: Date) -> (regular: Int, hard: Int, loose: Int) {
        let calendar = Calendar.current
        let logsForDay = logHistory.filter { calendar.isDate($0.timestamp, inSameDayAs: date) }
        let regular = logsForDay.filter { $0.poopScore == .regular }.count
        let hard = logsForDay.filter { $0.poopScore == .hard }.count
        let loose = logsForDay.filter { $0.poopScore == .loose }.count
        return (regular, hard, loose)
    }

    // Average hydration percentage based on timeframe
    func averageHydrationPercentage(for timeframe: String) -> CGFloat {
        let filteredLogs = getLogsForTimeframe(timeframe)
        let logsWithHydration = filteredLogs.compactMap { $0.hydrationPercentage }
        guard !logsWithHydration.isEmpty else { return 0.8 } // Default 80% if no data
        let average = logsWithHydration.reduce(0, +) / Double(logsWithHydration.count)
        return CGFloat(average)
    }

    // Average fiber percentage based on timeframe
    func averageFiberPercentage(for timeframe: String) -> CGFloat {
        let filteredLogs = getLogsForTimeframe(timeframe)
        let logsWithFiber = filteredLogs.compactMap { $0.fiberPercentage }
        guard !logsWithFiber.isEmpty else { return 0.3 } // Default 30% if no data
        let average = logsWithFiber.reduce(0, +) / Double(logsWithFiber.count)
        return CGFloat(average)
    }

    // Average blood percentage based on timeframe
    func averageBloodPercentage(for timeframe: String) -> CGFloat {
        let filteredLogs = getLogsForTimeframe(timeframe)
        guard !filteredLogs.isEmpty else { return 0.0 }
        let average = filteredLogs.map { $0.bloodPercentage }.reduce(0, +) / Double(filteredLogs.count)
        return CGFloat(average)
    }

    // Helper function to get logs for a specific timeframe
    func getLogsForTimeframe(_ timeframe: String) -> [Log] {
        let calendar = Calendar.current
        let now = Date()

        switch timeframe {
        case "TODAY":
            return logHistory.filter { calendar.isDateInToday($0.timestamp) }
        case "WEEK":
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: now)!
            return logHistory.filter { $0.timestamp >= weekAgo }
        case "MONTH":
            let monthAgo = calendar.date(byAdding: .month, value: -1, to: now)!
            return logHistory.filter { $0.timestamp >= monthAgo }
        default:
            return Array(logHistory.prefix(10)) // Default to recent logs
        }
    }

    // MARK: - Log Management

    func addLog(_ log: Log) {
        logHistory.append(log)
        logHistory.sort { $0.timestamp > $1.timestamp }
        UserDefaultsService.shared.saveLogs(logHistory)
    }

    func updateLog(_ updatedLog: Log) {
        if let index = logHistory.firstIndex(where: { $0.id == updatedLog.id }) {
            logHistory[index] = updatedLog
            logHistory.sort { $0.timestamp > $1.timestamp }
            UserDefaultsService.shared.saveLogs(logHistory)
        }
    }

    func deleteLog(_ log: Log) {
        logHistory.removeAll { $0.id == log.id }
        UserDefaultsService.shared.saveLogs(logHistory)
        Task {
            try? await FirebaseService.shared.deleteLog(log.id)
            if log.imageURL != nil {
                try? await FirebaseService.shared.deleteImage(for: log.id)
            }
        }
    }

    func deleteLog(at id: UUID) {
        let log = logHistory.first { $0.id == id }
        logHistory.removeAll { $0.id == id }
        UserDefaultsService.shared.saveLogs(logHistory)
        Task {
            try? await FirebaseService.shared.deleteLog(id)
            if log?.imageURL != nil {
                try? await FirebaseService.shared.deleteImage(for: id)
            }
        }
    }

    // MARK: - Firestore Sync

    func loadFromFirestore() async {
        do {
            let cloudLogs = try await FirebaseService.shared.loadLogs()
            await MainActor.run {
                mergeCloudLogs(cloudLogs)
            }
        } catch {
            // Offline or not authenticated — local data is fine
        }
    }

    private func mergeCloudLogs(_ cloudLogs: [Log]) {
        var merged = Dictionary(uniqueKeysWithValues: logHistory.map { ($0.id, $0) })

        for cloudLog in cloudLogs {
            if let existing = merged[cloudLog.id] {
                // Cloud wins for imageURL if local doesn't have one
                if existing.imageURL == nil && cloudLog.imageURL != nil {
                    var updated = existing
                    updated.imageURL = cloudLog.imageURL
                    updated.isManualEntry = cloudLog.isManualEntry
                    merged[cloudLog.id] = updated
                }
            } else {
                // Log only exists in cloud — add it
                merged[cloudLog.id] = cloudLog
            }
        }

        logHistory = Array(merged.values).sorted { $0.timestamp > $1.timestamp }
        UserDefaultsService.shared.saveLogs(logHistory)
    }

    func createManualLog(
        type: Log.PoopType,
        color: Log.PoopColor,
        size: Log.PoopSize,
        containsBlood: Bool,
        timestamp: Date
    ) -> Log {
        // Categorize based on type
        let category = Log.categorizePoopType(type)

        // Calculate hydration and fiber based on PoopType
        let hydration = hydrationForPoopType(type)
        let fiber = fiberForPoopType(type)
        let bloodPercentage = containsBlood ? 1.0 : 0.0

        return Log(
            poopScore: category,
            type: type,
            color: color,
            size: size,
            bloodPercentage: bloodPercentage,
            hydrationPercentage: hydration,
            fiberPercentage: fiber,
            timestamp: timestamp,
            analysis: generateAnalysisText(
                category: category,
                type: type,
                bloodPercentage: bloodPercentage
            )
        )
    }

    // Hydration percentage based on PoopType (lower = dehydrated, higher = well hydrated)
    private func hydrationForPoopType(_ type: Log.PoopType) -> Double {
        switch type {
        case .separateHardLumps: return 0.2   // Type 1 - Very dehydrated
        case .lumpySausage: return 0.4        // Type 2 - Dehydrated
        case .crackedSausage: return 0.7      // Type 3 - Good hydration
        case .smoothSausage: return 0.9       // Type 4 - Excellent hydration
        case .softBlobs: return 0.6           // Type 5 - Moderate hydration
        case .fluffyPieces: return 0.3        // Type 6 - Poor hydration
        case .watery: return 0.1              // Type 7 - Very poor hydration (diarrhea)
        }
    }

    // Fiber percentage based on PoopType (lower = low fiber, higher = good fiber)
    private func fiberForPoopType(_ type: Log.PoopType) -> Double {
        switch type {
        case .separateHardLumps: return 0.2   // Type 1 - Low fiber
        case .lumpySausage: return 0.3        // Type 2 - Low-moderate fiber
        case .crackedSausage: return 0.7      // Type 3 - Good fiber
        case .smoothSausage: return 0.8       // Type 4 - Excellent fiber
        case .softBlobs: return 0.5           // Type 5 - Moderate fiber
        case .fluffyPieces: return 0.4        // Type 6 - Low-moderate fiber
        case .watery: return 0.2              // Type 7 - Low fiber (poor digestion)
        }
    }

    // MARK: - Weekly Heatmap Data

    struct HeatmapDay: Identifiable {
        let id = UUID()
        let date: Date
        let dayLabel: String
        let score: Int? // nil = no data
    }

    func weeklyHeatmapData() -> [HeatmapDay] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today) // 1=Sun
        let startOfWeek = calendar.date(byAdding: .day, value: -(weekday - 2), to: today)! // Monday
        let labels = ["M", "T", "W", "T", "F", "S", "S"]

        return (0..<7).map { offset in
            let day = calendar.date(byAdding: .day, value: offset, to: startOfWeek)!
            let logsForDay = logHistory.filter { calendar.isDate($0.timestamp, inSameDayAs: day) }
            let score: Int? = logsForDay.isEmpty ? nil : logsForDay.reduce(0) { $0 + calculatePoopScore(for: $1) } / logsForDay.count
            return HeatmapDay(date: day, dayLabel: labels[offset], score: score)
        }
    }

    struct BestDay {
        let dayName: String
        let score: Int
        let date: Date
    }

    func bestDayThisWeek() -> BestDay? {
        let data = weeklyHeatmapData().compactMap { d -> (HeatmapDay, Int)? in
            guard let s = d.score else { return nil }
            return (d, s)
        }
        guard let best = data.max(by: { $0.1 < $1.1 }) else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return BestDay(dayName: formatter.string(from: best.0.date), score: best.1, date: best.0.date)
    }

    // MARK: - Category Breakdown

    struct CategoryBreakdown {
        let regular: Int
        let hard: Int
        let loose: Int
        var total: Int { regular + hard + loose }
        var dominantCategory: String {
            if regular >= hard && regular >= loose { return "Good" }
            if hard >= loose { return "Hard" }
            return "Loose"
        }
        var dominantPercentage: Int {
            guard total > 0 else { return 0 }
            let dominant = max(regular, max(hard, loose))
            return Int(Double(dominant) / Double(total) * 100)
        }
    }

    func categoryBreakdown(for timeframe: String) -> CategoryBreakdown {
        let logs = getLogsForTimeframe(timeframe)
        let regular = logs.filter { $0.poopScore == .regular }.count
        let hard = logs.filter { $0.poopScore == .hard }.count
        let loose = logs.filter { $0.poopScore == .loose }.count
        return CategoryBreakdown(regular: regular, hard: hard, loose: loose)
    }

    // MARK: - Hourly Distribution (Consistency Clock)

    struct HourlyBucket: Identifiable {
        let id = UUID()
        let hour: Int
        let count: Int
    }

    func hourlyDistribution() -> [HourlyBucket] {
        let calendar = Calendar.current
        var counts = Array(repeating: 0, count: 24)
        for log in logHistory {
            let hour = calendar.component(.hour, from: log.timestamp)
            counts[hour] += 1
        }
        return counts.enumerated().map { HourlyBucket(hour: $0.offset, count: $0.element) }
    }

    func peakPoopHour() -> String {
        let dist = hourlyDistribution()
        guard let peak = dist.max(by: { $0.count < $1.count }), peak.count > 0 else { return "No data" }
        let hour = peak.hour
        if hour == 0 { return "12am" }
        if hour < 12 { return "\(hour)am" }
        if hour == 12 { return "12pm" }
        return "\(hour - 12)pm"
    }

    // MARK: - Best Day (All Time)

    func bestDayAllTime() -> BestDay? {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: logHistory) { calendar.startOfDay(for: $0.timestamp) }
        let scored = grouped.compactMap { (date, logs) -> (Date, Int)? in
            guard !logs.isEmpty else { return nil }
            let avg = logs.reduce(0) { $0 + calculatePoopScore(for: $1) } / logs.count
            return (date, avg)
        }
        guard let best = scored.max(by: { $0.1 < $1.1 }) else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return BestDay(dayName: formatter.string(from: best.0), score: best.1, date: best.0)
    }

    // MARK: - AI Insights Generation

    struct Insight: Identifiable {
        let id = UUID()
        let icon: String
        let iconColor: Color
        let title: String
        let description: String
    }

    func generateInsights(for timeframe: String) -> [Insight] {
        var insights: [Insight] = []
        let logs = getLogsForTimeframe(timeframe)

        guard !logs.isEmpty else {
            return [Insight(
                icon: "info.circle.fill",
                iconColor: Color(hex: "#78909C"),
                title: "No data yet",
                description: "Start logging to see your personalized insights."
            )]
        }

        // 1. Good poop percentage insight
        let goodCount = logs.filter { calculatePoopScore(for: $0) >= 70 }.count
        let goodPercentage = Int(Double(goodCount) / Double(logs.count) * 100)
        let timeframeLabel = timeframe == "TODAY" ? "today" : (timeframe == "WEEK" ? "this week" : "this month")

        if goodPercentage >= 70 {
            insights.append(Insight(
                icon: "checkmark.circle.fill",
                iconColor: Color(hex: "#19B888"),
                title: "Great gut health!",
                description: "\(goodPercentage)% of your logs were good \(timeframeLabel). Keep up the excellent work!"
            ))
        } else if goodPercentage >= 40 {
            insights.append(Insight(
                icon: "exclamationmark.circle.fill",
                iconColor: Color(hex: "#FFA726"),
                title: "Room for improvement",
                description: "\(goodPercentage)% of your logs were good \(timeframeLabel). Consider increasing fiber and water intake."
            ))
        } else {
            insights.append(Insight(
                icon: "exclamationmark.triangle.fill",
                iconColor: Color(hex: "#E53935"),
                title: "Needs attention",
                description: "Only \(goodPercentage)% of your logs were good \(timeframeLabel). Monitor your diet closely."
            ))
        }

        // 2. Blood detection insight
        let logsWithBlood = logs.filter { $0.bloodPercentage > 0 }
        if !logsWithBlood.isEmpty {
            let daysSinceLastBlood = Calendar.current.dateComponents([.day], from: logsWithBlood.first!.timestamp, to: Date()).day ?? 0
            insights.append(Insight(
                icon: "drop.fill",
                iconColor: Color(hex: "#E53935"),
                title: "Blood detected",
                description: "Blood was logged \(logsWithBlood.count) time\(logsWithBlood.count == 1 ? "" : "s") \(timeframeLabel). Most recently: \(daysSinceLastBlood == 0 ? "today" : "\(daysSinceLastBlood) day\(daysSinceLastBlood == 1 ? "" : "s") ago")."
            ))
        }

        // 3. Hydration insight
        let avgHydration = averageHydrationPercentage(for: timeframe)
        if avgHydration < 0.5 {
            insights.append(Insight(
                icon: "drop.triangle.fill",
                iconColor: Color(hex: "#4FC3F7"),
                title: "Low hydration detected",
                description: "Your hydration levels are low (\(Int(avgHydration * 100))%). Try drinking more water throughout the day."
            ))
        } else if avgHydration >= 0.8 {
            insights.append(Insight(
                icon: "drop.fill",
                iconColor: Color(hex: "#4FC3F7"),
                title: "Well hydrated!",
                description: "Your hydration is excellent at \(Int(avgHydration * 100))%. This contributes to healthy digestion."
            ))
        }

        // 4. Consistency insight (for week/month)
        if timeframe != "TODAY" && logs.count >= 3 {
            let looseCount = logs.filter { $0.poopScore == .loose }.count
            let hardCount = logs.filter { $0.poopScore == .hard }.count

            if looseCount > logs.count / 2 {
                insights.append(Insight(
                    icon: "waveform.path",
                    iconColor: Color(hex: "#008CFF"),
                    title: "Frequent loose stools",
                    description: "You've had loose stools \(looseCount) times \(timeframeLabel). Consider checking for food sensitivities."
                ))
            } else if hardCount > logs.count / 2 {
                insights.append(Insight(
                    icon: "circle.grid.2x2.fill",
                    iconColor: Color(hex: "#FF7A33"),
                    title: "Frequent hard stools",
                    description: "You've had hard stools \(hardCount) times \(timeframeLabel). Increase fiber and water intake."
                ))
            }
        }

        return insights
    }

    // Pattern stats for insights page
    struct PatternStat: Identifiable {
        let id = UUID()
        let value: String
        let label: String
        let trend: String?  // "up", "down", or nil
        let trendValue: String?
    }

    func getPatternStats(for timeframe: String) -> [PatternStat] {
        let logs = getLogsForTimeframe(timeframe)
        var stats: [PatternStat] = []

        // Average score
        let avgScore = averagePoopScore(for: timeframe)
        stats.append(PatternStat(value: "\(avgScore)", label: "Avg Score", trend: nil, trendValue: nil))

        // Total logs
        stats.append(PatternStat(value: "\(logs.count)", label: "Total Logs", trend: nil, trendValue: nil))

        // Regular percentage
        let regularCount = logs.filter { $0.poopScore == .regular }.count
        let regularPct = logs.isEmpty ? 0 : Int(Double(regularCount) / Double(logs.count) * 100)
        stats.append(PatternStat(value: "\(regularPct)%", label: "Regular", trend: nil, trendValue: nil))

        return stats
    }

    private func generateAnalysisText(
        category: Log.PoopCategory,
        type: Log.PoopType,
        bloodPercentage: Double
    ) -> String {
        var analysis = ""

        // Base analysis on category
        switch category {
        case .regular:
            analysis = "Excellent! Your stool appears healthy and well-formed."
        case .loose:
            analysis = "Your stool is loose. Consider monitoring your diet and hydration."
        case .hard:
            analysis = "Your stool is hard. Try increasing fiber and water intake."
        }

        // Add blood warning if significant
        if bloodPercentage > 0.05 { // More than 5%
            analysis += " Significant blood present (\(Int(bloodPercentage * 100))%) - consult a doctor if this persists."
        } else if bloodPercentage > 0.0 {
            analysis += " Minor traces of blood detected (\(Int(bloodPercentage * 100))%)."
        }

        return analysis
    }

    // MARK: - Advanced Insights System

    enum InsightType: String {
        case trend = "Trend"
        case frequency = "Frequency"
        case pattern = "Pattern"
        case anomaly = "Anomaly"
        case recommendation = "Recommendation"
        case milestone = "Milestone"
    }

    enum InsightPriority: Int, Comparable {
        case critical = 4
        case high = 3
        case medium = 2
        case low = 1

        static func < (lhs: InsightPriority, rhs: InsightPriority) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }
    }

    struct AdvancedInsight: Identifiable {
        let id = UUID()
        let type: InsightType
        let priority: InsightPriority
        let icon: String
        let iconColor: Color
        let title: String
        let description: String
        let metric: String?          // e.g., "↑12%"
        let actionable: String?      // Specific recommendation
    }

    struct PersonalBaseline {
        var averageLogsPerDay: Double
        var averagePoopScore: Double
        var averageHydration: Double
        var averageFiber: Double
        var mostCommonType: Log.PoopType?
        var mostCommonTimeOfDay: String?
    }

    // Calculate personal baseline from all historical data
    func calculatePersonalBaseline() -> PersonalBaseline {
        guard !logHistory.isEmpty else {
            return PersonalBaseline(
                averageLogsPerDay: 0,
                averagePoopScore: 0,
                averageHydration: 0,
                averageFiber: 0,
                mostCommonType: nil,
                mostCommonTimeOfDay: nil
            )
        }

        let calendar = Calendar.current

        // Calculate days with logs
        let uniqueDays = Set(logHistory.map { calendar.startOfDay(for: $0.timestamp) })
        let logsPerDay = Double(logHistory.count) / max(Double(uniqueDays.count), 1)

        // Average poop score
        let avgScore = Double(logHistory.reduce(0) { $0 + calculatePoopScore(for: $1) }) / Double(logHistory.count)

        // Average hydration
        let hydrationLogs = logHistory.compactMap { $0.hydrationPercentage }
        let avgHydration = hydrationLogs.isEmpty ? 0 : hydrationLogs.reduce(0, +) / Double(hydrationLogs.count)

        // Average fiber
        let fiberLogs = logHistory.compactMap { $0.fiberPercentage }
        let avgFiber = fiberLogs.isEmpty ? 0 : fiberLogs.reduce(0, +) / Double(fiberLogs.count)

        // Most common type
        var typeCounts: [Log.PoopType: Int] = [:]
        for log in logHistory {
            typeCounts[log.type, default: 0] += 1
        }
        let mostCommonType = typeCounts.max(by: { $0.value < $1.value })?.key

        // Most common time of day
        var timeOfDayCounts: [String: Int] = ["Morning": 0, "Afternoon": 0, "Evening": 0, "Night": 0]
        for log in logHistory {
            let hour = calendar.component(.hour, from: log.timestamp)
            switch hour {
            case 5..<12: timeOfDayCounts["Morning"]! += 1
            case 12..<17: timeOfDayCounts["Afternoon"]! += 1
            case 17..<21: timeOfDayCounts["Evening"]! += 1
            default: timeOfDayCounts["Night"]! += 1
            }
        }
        let mostCommonTime = timeOfDayCounts.max(by: { $0.value < $1.value })?.key

        return PersonalBaseline(
            averageLogsPerDay: logsPerDay,
            averagePoopScore: avgScore,
            averageHydration: avgHydration,
            averageFiber: avgFiber,
            mostCommonType: mostCommonType,
            mostCommonTimeOfDay: mostCommonTime
        )
    }

    // Get logs for previous period (for comparison)
    private func getLogsForPreviousPeriod(_ timeframe: String) -> [Log] {
        let calendar = Calendar.current
        let now = Date()

        switch timeframe {
        case "TODAY":
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: now) else { return [] }
            return logHistory.filter { calendar.isDate($0.timestamp, inSameDayAs: yesterday) }
        case "WEEK":
            let twoWeeksAgo = calendar.date(byAdding: .day, value: -14, to: now)!
            let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: now)!
            return logHistory.filter { $0.timestamp >= twoWeeksAgo && $0.timestamp < oneWeekAgo }
        case "MONTH":
            let twoMonthsAgo = calendar.date(byAdding: .month, value: -2, to: now)!
            let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: now)!
            return logHistory.filter { $0.timestamp >= twoMonthsAgo && $0.timestamp < oneMonthAgo }
        default:
            return []
        }
    }

    // Time-of-day distribution
    func getTimeOfDayDistribution(for timeframe: String) -> [String: Int] {
        let logs = getLogsForTimeframe(timeframe)
        let calendar = Calendar.current

        var distribution: [String: Int] = ["Morning": 0, "Afternoon": 0, "Evening": 0, "Night": 0]

        for log in logs {
            let hour = calendar.component(.hour, from: log.timestamp)
            switch hour {
            case 5..<12: distribution["Morning"]! += 1
            case 12..<17: distribution["Afternoon"]! += 1
            case 17..<21: distribution["Evening"]! += 1
            default: distribution["Night"]! += 1
            }
        }

        return distribution
    }

    // Day-of-week distribution
    func getDayOfWeekDistribution(for timeframe: String) -> [String: Int] {
        let logs = getLogsForTimeframe(timeframe)
        let calendar = Calendar.current
        let dayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

        var distribution: [String: Int] = [:]
        for day in dayNames { distribution[day] = 0 }

        for log in logs {
            let weekday = calendar.component(.weekday, from: log.timestamp) - 1
            distribution[dayNames[weekday]]! += 1
        }

        return distribution
    }

    // Generate advanced insights — data-driven, diverse, prioritized
    func generateAdvancedInsights(for timeframe: String) -> [AdvancedInsight] {
        var insights: [AdvancedInsight] = []
        let currentLogs = getLogsForTimeframe(timeframe)
        let previousLogs = getLogsForPreviousPeriod(timeframe)

        guard !currentLogs.isEmpty else {
            return [AdvancedInsight(
                type: .recommendation,
                priority: .low,
                icon: "plus.circle.fill",
                iconColor: Theme.Colors.primary,
                title: "Start Tracking",
                description: "Log your first bowel movement to begin tracking your gut health patterns.",
                metric: nil,
                actionable: "Tap the + button to add your first log"
            )]
        }

        let periodLabel = timeframe == "TODAY" ? "today" : (timeframe == "WEEK" ? "this week" : "this month")
        let previousLabel = timeframe == "TODAY" ? "yesterday" : (timeframe == "WEEK" ? "last week" : "last month")
        let calendar = Calendar.current
        let totalCount = currentLogs.count

        // MARK: 9. Blood detection — MEDICAL FLAG (highest priority)
        let bloodyLogs = currentLogs.filter { $0.bloodPercentage > 0 }
        if !bloodyLogs.isEmpty {
            let n = bloodyLogs.count
            let pct = (Double(n) / Double(totalCount)) * 100
            insights.append(AdvancedInsight(
                type: .anomaly,
                priority: pct > 10 ? .critical : .high,
                icon: "exclamationmark.triangle.fill",
                iconColor: Theme.Colors.blood,
                title: "Blood Detected",
                description: "Blood appeared in \(n) of your \(totalCount) log\(totalCount == 1 ? "" : "s") \(periodLabel). Even small traces are worth tracking — if you see it again, it's time to talk to a doctor.",
                metric: "\(n) log\(n == 1 ? "" : "s")",
                actionable: "If recurring, consult a physician"
            ))
        }

        // MARK: 4. Color anomalies (>15% non-mediumBrown of concerning colors)
        let concerningColors: [Log.PoopColor] = [.yellow, .green, .black, .red]
        let oddColorLogs = currentLogs.filter { concerningColors.contains($0.color) }
        if totalCount >= 4 && !oddColorLogs.isEmpty {
            let oddPct = Double(oddColorLogs.count) / Double(totalCount)
            if oddPct > 0.15 {
                // Identify which color dominates
                var colorCounts: [Log.PoopColor: Int] = [:]
                for log in oddColorLogs { colorCounts[log.color, default: 0] += 1 }
                if let topColor = colorCounts.max(by: { $0.value < $1.value })?.key {
                    let (label, hint) = colorMeta(for: topColor)
                    insights.append(AdvancedInsight(
                        type: .anomaly,
                        priority: (topColor == .black || topColor == .red) ? .high : .medium,
                        icon: "eyedropper.halffull",
                        iconColor: (topColor == .black || topColor == .red) ? Theme.Colors.blood : Theme.Colors.amber,
                        title: "\(label) Color Showing Up",
                        description: "\(Int(oddPct * 100))% of your stool came out \(label.lowercased()) \(periodLabel). \(hint)",
                        metric: "\(Int(oddPct * 100))%",
                        actionable: (topColor == .black || topColor == .red) ? "If this persists more than 2 days, see a doctor" : "Note any recent diet changes"
                    ))
                }
            }
        }

        // MARK: 5. Frequency — logs per day
        let uniqueDays = Set(currentLogs.map { calendar.startOfDay(for: $0.timestamp) })
        let periodDays: Double = {
            switch timeframe {
            case "TODAY": return 1
            case "WEEK": return 7
            case "MONTH": return 30
            default: return max(Double(uniqueDays.count), 1)
            }
        }()
        let logsPerDay = Double(totalCount) / periodDays

        if timeframe != "TODAY" {
            if logsPerDay < 0.5 {
                insights.append(AdvancedInsight(
                    type: .frequency,
                    priority: .high,
                    icon: "tortoise.fill",
                    iconColor: Theme.Colors.hard,
                    title: "Going Less Than Usual",
                    description: "You averaged \(String(format: "%.1f", logsPerDay)) movements per day \(periodLabel). Going less than every other day can be a sign of constipation or low fiber.",
                    metric: String(format: "%.1f/day", logsPerDay),
                    actionable: "Add fiber-rich foods and 1-2 extra glasses of water"
                ))
            } else if logsPerDay > 3 {
                insights.append(AdvancedInsight(
                    type: .frequency,
                    priority: .high,
                    icon: "hare.fill",
                    iconColor: Theme.Colors.loose,
                    title: "Going Much More Than Usual",
                    description: "You're averaging \(String(format: "%.1f", logsPerDay)) movements per day \(periodLabel) — that's on the high side and can lead to dehydration.",
                    metric: String(format: "%.1f/day", logsPerDay),
                    actionable: "If this lasts more than 2 days, check for food triggers"
                ))
            } else if logsPerDay >= 1 && logsPerDay <= 2 {
                insights.append(AdvancedInsight(
                    type: .frequency,
                    priority: .low,
                    icon: "chart.bar.fill",
                    iconColor: Theme.Colors.good,
                    title: "Healthy Frequency",
                    description: "You're going \(String(format: "%.1f", logsPerDay)) times per day on average — right in the sweet spot for a healthy gut.",
                    metric: String(format: "%.1f/day", logsPerDay),
                    actionable: nil
                ))
            }
        }

        // MARK: 2. Bristol type distribution
        if totalCount >= 3 {
            var typeCounts: [Log.PoopType: Int] = [:]
            for log in currentLogs { typeCounts[log.type, default: 0] += 1 }

            let idealCount = (typeCounts[.crackedSausage] ?? 0) + (typeCounts[.smoothSausage] ?? 0)
            let hardCount = (typeCounts[.separateHardLumps] ?? 0) + (typeCounts[.lumpySausage] ?? 0)
            let looseCount = (typeCounts[.softBlobs] ?? 0) + (typeCounts[.fluffyPieces] ?? 0) + (typeCounts[.watery] ?? 0)

            if let dominant = typeCounts.max(by: { $0.value < $1.value }) {
                let dominantPct = Int((Double(dominant.value) / Double(totalCount)) * 100)
                let (typeName, typeNum) = bristolMeta(for: dominant.key)

                if [Log.PoopType.crackedSausage, .smoothSausage].contains(dominant.key) && dominantPct >= 50 {
                    insights.append(AdvancedInsight(
                        type: .pattern,
                        priority: .low,
                        icon: "checkmark.seal.fill",
                        iconColor: Theme.Colors.good,
                        title: "High-Score Pattern",
                        description: "\(dominantPct)% of your logs \(periodLabel) scored in the healthy range. That's exactly what a happy gut looks like.",
                        metric: "\(dominantPct)%",
                        actionable: nil
                    ))
                } else if hardCount > looseCount && hardCount > idealCount {
                    let hardPct = Int((Double(hardCount) / Double(totalCount)) * 100)
                    insights.append(AdvancedInsight(
                        type: .pattern,
                        priority: .high,
                        icon: "chart.pie.fill",
                        iconColor: Theme.Colors.hard,
                        title: "Leaning Hard",
                        description: "\(hardPct)% of your logs \(periodLabel) scored on the hard, low-score end — the constipated side. Your gut needs more help moving things through.",
                        metric: "\(hardPct)% hard",
                        actionable: "Bump up fiber, water, and try a 10-minute walk after meals"
                    ))
                } else if looseCount > hardCount && looseCount > idealCount {
                    let loosePct = Int((Double(looseCount) / Double(totalCount)) * 100)
                    insights.append(AdvancedInsight(
                        type: .pattern,
                        priority: .high,
                        icon: "chart.pie.fill",
                        iconColor: Theme.Colors.loose,
                        title: "Leaning Loose",
                        description: "\(loosePct)% of your logs \(periodLabel) scored loose. Loose patterns can point to food sensitivities or stress.",
                        metric: "\(loosePct)% loose",
                        actionable: "Try a low-FODMAP day and see if it settles"
                    ))
                }
            }
        }

        // MARK: 3. Consistency score (variance across Bristol types)
        if totalCount >= 5 {
            let typeNums = currentLogs.map { bristolNumber(for: $0.type) }
            let mean = Double(typeNums.reduce(0, +)) / Double(typeNums.count)
            let variance = typeNums.reduce(0.0) { $0 + pow(Double($1) - mean, 2) } / Double(typeNums.count)

            if variance < 0.75 {
                insights.append(AdvancedInsight(
                    type: .pattern,
                    priority: .low,
                    icon: "waveform.path.ecg",
                    iconColor: Theme.Colors.good,
                    title: "Rock-Steady Consistency",
                    description: "Your Bristol types barely moved \(periodLabel). A consistent gut is a happy gut.",
                    metric: nil,
                    actionable: nil
                ))
            } else if variance > 3.0 {
                insights.append(AdvancedInsight(
                    type: .anomaly,
                    priority: .medium,
                    icon: "waveform.path",
                    iconColor: Theme.Colors.amber,
                    title: "Erratic Pattern",
                    description: "Your stool type swung all over the Bristol scale \(periodLabel). That kind of variability often tracks with stress, travel, or shifting eating habits.",
                    metric: nil,
                    actionable: "Look for what changed — sleep, food, or schedule"
                ))
            }
        }

        // MARK: 1. Timing patterns + anomaly vs baseline
        if totalCount >= 5 {
            let timeDistribution = getTimeOfDayDistribution(for: timeframe)
            if let peakTime = timeDistribution.max(by: { $0.value < $1.value }), peakTime.value > 0 {
                let totalTimed = timeDistribution.values.reduce(0, +)
                let pct = totalTimed > 0 ? Int((Double(peakTime.value) / Double(totalTimed)) * 100) : 0
                let baseline = calculatePersonalBaseline()

                // Anomaly: current peak differs from all-time peak
                if let baselinePeak = baseline.mostCommonTimeOfDay,
                   baselinePeak != peakTime.key,
                   pct >= 40,
                   logHistory.count >= 20 {
                    insights.append(AdvancedInsight(
                        type: .anomaly,
                        priority: .medium,
                        icon: "clock.badge.exclamationmark.fill",
                        iconColor: Theme.Colors.amber,
                        title: "Your Timing Shifted",
                        description: "You usually go in the \(baselinePeak.lowercased()), but \(periodLabel) you shifted to the \(peakTime.key.lowercased()). Stress or a schedule change can do this.",
                        metric: "\(pct)% \(peakTime.key.lowercased())",
                        actionable: "Check if your sleep or routine changed recently"
                    ))
                } else if pct >= 40 {
                    insights.append(AdvancedInsight(
                        type: .pattern,
                        priority: .low,
                        icon: "clock.fill",
                        iconColor: Theme.Colors.iconBlue400,
                        title: "Your Gut Prefers \(peakTime.key)s",
                        description: "\(pct)% of your movements happened in the \(peakTime.key.lowercased()) \(periodLabel). That's a strong circadian rhythm — your body knows the drill.",
                        metric: "\(pct)%",
                        actionable: nil
                    ))
                }
            }
        }

        // MARK: 6. Streak — milestones and breaks
        let streak = regularStreak
        let longest = longestRegularStreak
        let streakMilestones = [30, 14, 7, 3]
        if let hit = streakMilestones.first(where: { streak >= $0 }) {
            let title: String = {
                switch hit {
                case 30: return "30-Day Iron Gut"
                case 14: return "Two Solid Weeks"
                case 7: return "One-Week Streak"
                default: return "\(streak)-Day Streak"
                }
            }()
            insights.append(AdvancedInsight(
                type: .milestone,
                priority: hit >= 14 ? .medium : .low,
                icon: "flame.fill",
                iconColor: Theme.Colors.orange,
                title: title,
                description: "You've had \(streak) regular movements in a row. Whatever you're doing, keep doing it.",
                metric: "🔥 \(streak)",
                actionable: nil
            ))
        } else if streak == 0 && longest >= 5 && logHistory.count >= 10 {
            // Streak recently broke
            insights.append(AdvancedInsight(
                type: .anomaly,
                priority: .medium,
                icon: "flame",
                iconColor: Theme.Colors.textSecondary,
                title: "Streak Broke",
                description: "Your last streak hit \(longest) regular days in a row. One off-day doesn't undo that — get back on the wagon.",
                metric: "Best: \(longest)",
                actionable: "Drink a glass of water and aim for a clean log next time"
            ))
        }

        // MARK: 7. Day-of-week worst/best (only with enough data)
        if timeframe != "TODAY" && totalCount >= 10 {
            let dayLogs = Dictionary(grouping: currentLogs) { log -> String in
                let formatter = DateFormatter()
                formatter.dateFormat = "EEEE"
                return formatter.string(from: log.timestamp)
            }
            var dayAvg: [(day: String, score: Int, count: Int)] = []
            for (day, logs) in dayLogs where logs.count >= 2 {
                let avg = logs.reduce(0) { $0 + calculatePoopScore(for: $1) } / logs.count
                dayAvg.append((day, avg, logs.count))
            }
            if dayAvg.count >= 3,
               let worst = dayAvg.min(by: { $0.score < $1.score }),
               let best = dayAvg.max(by: { $0.score < $1.score }),
               best.score - worst.score >= 15 {
                insights.append(AdvancedInsight(
                    type: .pattern,
                    priority: .low,
                    icon: "calendar.badge.clock",
                    iconColor: Theme.Colors.iconBlue400,
                    title: "\(worst.day)s Are Rough",
                    description: "\(worst.day)s scored \(worst.score) on average vs \(best.score) on \(best.day)s. Something about that day isn't agreeing with your gut.",
                    metric: "\(best.score - worst.score) pts",
                    actionable: "Think about what's different — meals, stress, sleep"
                ))
            }
        }

        // MARK: 12. Best single day callout
        if timeframe != "TODAY" && totalCount >= 5 {
            let dayGroups = Dictionary(grouping: currentLogs) { calendar.startOfDay(for: $0.timestamp) }
            let scored = dayGroups.compactMap { (date, logs) -> (Date, Int)? in
                guard !logs.isEmpty else { return nil }
                let avg = logs.reduce(0) { $0 + calculatePoopScore(for: $1) } / logs.count
                return (date, avg)
            }
            if let best = scored.max(by: { $0.1 < $1.1 }), best.1 >= 80, scored.count >= 3 {
                let formatter = DateFormatter()
                formatter.dateFormat = "EEEE"
                let dayName = formatter.string(from: best.0)
                insights.append(AdvancedInsight(
                    type: .milestone,
                    priority: .low,
                    icon: "star.fill",
                    iconColor: Theme.Colors.yellow,
                    title: "Best Day: \(dayName)",
                    description: "Your highest-scoring day \(periodLabel) was \(dayName) at \(best.1)/100. Whatever you ate or did — bottle it.",
                    metric: "\(best.1)/100",
                    actionable: nil
                ))
            }
        }

        // MARK: 8. Trend vs previous period
        if !previousLogs.isEmpty && totalCount >= 3 {
            let currentAvg = Double(currentLogs.reduce(0) { $0 + calculatePoopScore(for: $1) }) / Double(totalCount)
            let prevAvg = Double(previousLogs.reduce(0) { $0 + calculatePoopScore(for: $1) }) / Double(previousLogs.count)
            let pctChange = prevAvg > 0 ? ((currentAvg - prevAvg) / prevAvg) * 100 : 0

            if abs(pctChange) > 8 {
                let up = pctChange > 0
                insights.append(AdvancedInsight(
                    type: .trend,
                    priority: up ? .medium : .high,
                    icon: up ? "chart.line.uptrend.xyaxis" : "chart.line.downtrend.xyaxis",
                    iconColor: up ? Theme.Colors.good : Theme.Colors.amber,
                    title: up ? "Trending Up" : "Trending Down",
                    description: "Your gut score is \(up ? "up" : "down") \(Int(abs(pctChange)))% vs \(previousLabel) (\(Int(currentAvg)) vs \(Int(prevAvg)) avg).",
                    metric: "\(up ? "↑" : "↓")\(Int(abs(pctChange)))%",
                    actionable: up ? nil : "Look at what changed in the last \(timeframe == "WEEK" ? "week" : "month")"
                ))
            }
        }

        // MARK: 10. Hydration — conditional only
        let avgHydration = averageHydrationPercentage(for: timeframe)
        let hydrationLogs = currentLogs.compactMap { $0.hydrationPercentage }
        if !hydrationLogs.isEmpty && avgHydration < 0.5 {
            insights.append(AdvancedInsight(
                type: .recommendation,
                priority: .medium,
                icon: "drop.fill",
                iconColor: Theme.Colors.hydration,
                title: "You're Running Dry",
                description: "Your stool's been on the dehydrated side \(periodLabel) — averaging \(Int(avgHydration * 100))% hydration. Hard, lumpy stool is usually the first sign.",
                metric: "\(Int(avgHydration * 100))%",
                actionable: "Add 2 extra glasses of water tomorrow"
            ))
        }

        // MARK: 11. Fiber — conditional only
        let avgFiber = averageFiberPercentage(for: timeframe)
        let fiberLogs = currentLogs.compactMap { $0.fiberPercentage }
        if !fiberLogs.isEmpty && avgFiber < 0.4 {
            insights.append(AdvancedInsight(
                type: .recommendation,
                priority: .medium,
                icon: "leaf.fill",
                iconColor: Theme.Colors.fiber,
                title: "Low on Fiber",
                description: "Your fiber signal sits at \(Int(avgFiber * 100))% \(periodLabel). Stool gets harder and slower to pass when fiber drops.",
                metric: "\(Int(avgFiber * 100))%",
                actionable: "Add one cup of veggies, berries, or oats per day"
            ))
        }

        // MARK: - Sort by priority (high first), cap at 8
        let sorted = insights.sorted { $0.priority > $1.priority }
        return Array(sorted.prefix(8))
    }

    // MARK: - Insight helpers

    private func bristolNumber(for type: Log.PoopType) -> Int {
        switch type {
        case .separateHardLumps: return 1
        case .lumpySausage:      return 2
        case .crackedSausage:    return 3
        case .smoothSausage:     return 4
        case .softBlobs:         return 5
        case .fluffyPieces:      return 6
        case .watery:            return 7
        }
    }

    private func bristolMeta(for type: Log.PoopType) -> (name: String, number: Int) {
        switch type {
        case .separateHardLumps: return ("Type 1 (hard lumps)", 1)
        case .lumpySausage:      return ("Type 2 (lumpy sausage)", 2)
        case .crackedSausage:    return ("Type 3 (cracked sausage)", 3)
        case .smoothSausage:     return ("Type 4 (smooth sausage)", 4)
        case .softBlobs:         return ("Type 5 (soft blobs)", 5)
        case .fluffyPieces:      return ("Type 6 (fluffy)", 6)
        case .watery:            return ("Type 7 (watery)", 7)
        }
    }

    private func colorMeta(for color: Log.PoopColor) -> (label: String, hint: String) {
        switch color {
        case .yellow:
            return ("Yellow", "Yellow stool can point to fat malabsorption or a fast-moving gut.")
        case .green:
            return ("Green", "Green is usually leafy greens or quick transit — rarely worrying by itself.")
        case .black:
            return ("Black", "Black stool can mean iron, dark foods, or upper-GI bleeding — pay attention.")
        case .red:
            return ("Red", "Red can be beets or blood. If you didn't eat anything red, take it seriously.")
        case .lightBrown:
            return ("Light Brown", "Lighter stool can indicate low bile or a fast transit.")
        case .darkBrown:
            return ("Dark Brown", "Dark brown is usually fine — common with iron-rich or protein-heavy meals.")
        case .mediumBrown:
            return ("Medium Brown", "Medium brown is the ideal — bile and bacteria doing their job.")
        }
    }

    // MARK: - Pooply v5: Rolling Score + Green Zone

    /// Headline Poop Score. Always rolling last 7 days regardless of UI timeframe.
    var rollingPoopScore7Day: Int {
        averagePoopScore(for: "WEEK")
    }

    /// Average score for the 7-day window before the current one — used for delta.
    var previousWeekScore7Day: Int {
        let cal = Calendar.current
        let now = Date()
        guard let twoWeeksAgo = cal.date(byAdding: .day, value: -14, to: now),
              let oneWeekAgo = cal.date(byAdding: .day, value: -7, to: now) else { return 0 }
        let prevLogs = logHistory.filter { $0.timestamp >= twoWeeksAgo && $0.timestamp < oneWeekAgo }
        guard !prevLogs.isEmpty else { return 0 }
        let total = prevLogs.reduce(0) { $0 + UserViewModel.calculatePoopScoreStatic(for: $1) }
        return total / prevLogs.count
    }

    /// Delta between current rolling 7 and previous 7.
    var poopScoreDelta7Day: Int {
        let prev = previousWeekScore7Day
        guard prev > 0 else { return 0 }
        return rollingPoopScore7Day - prev
    }

    /// Last 7 *log days* — used for the home strip of colored dots.
    /// Returns 7 elements, oldest first; nil for days with no log.
    var last7DayDominantTypes: [Log.PoopType?] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<7).map { offset -> Log.PoopType? in
            guard let day = cal.date(byAdding: .day, value: -(6 - offset), to: today) else { return nil }
            let logs = logHistory.filter { cal.isDate($0.timestamp, inSameDayAs: day) }
            guard !logs.isEmpty else { return nil }
            // Take the *worst* (lowest score) — that's the day's signal
            return logs.min(by: { UserViewModel.calculatePoopScoreStatic(for: $0) < UserViewModel.calculatePoopScoreStatic(for: $1) })?.type
        }
    }

    /// Is the date a Green Zone day? Bristol 3-5 + at least 1 log.
    /// (Personal frequency baseline integrated later when onboarding ships.)
    func isGreenZoneDay(_ date: Date) -> Bool {
        let cal = Calendar.current
        let logsForDay = logHistory.filter { cal.isDate($0.timestamp, inSameDayAs: date) }
        guard !logsForDay.isEmpty else { return false }
        return logsForDay.allSatisfy { isGreenZoneType($0.type) }
    }

    private func isGreenZoneType(_ type: Log.PoopType) -> Bool {
        switch type {
        case .smoothSausage, .crackedSausage, .softBlobs: return true  // Bristol 3, 4, 5
        default: return false
        }
    }

    /// Consecutive Green Zone days ending today (or yesterday if no logs yet today).
    var greenZoneStreak: Int {
        let cal = Calendar.current
        var streak = 0
        var dayCursor = cal.startOfDay(for: Date())

        let todayHasLogs = !logHistory.filter { cal.isDate($0.timestamp, inSameDayAs: dayCursor) }.isEmpty
        if !todayHasLogs {
            guard let yesterday = cal.date(byAdding: .day, value: -1, to: dayCursor) else { return 0 }
            dayCursor = yesterday
        }

        while isGreenZoneDay(dayCursor) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: dayCursor) else { break }
            dayCursor = prev
        }
        return streak
    }

    /// % of last 30 days that were Green Zone days.
    var greenZone30DayPercentage: Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        var greenCount = 0
        for offset in 0..<30 {
            guard let day = cal.date(byAdding: .day, value: -offset, to: today) else { continue }
            if isGreenZoneDay(day) { greenCount += 1 }
        }
        return Int(Double(greenCount) / 30.0 * 100)
    }

    /// "3h ago", "2d ago", "just now" — human-readable time-since-last.
    var timeSinceLastPoopString: String {
        guard let last = lastLog else { return "—" }
        let interval = Date().timeIntervalSince(last.timestamp)
        if interval < 60   { return "just now" }
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        if interval < 86400 { return "\(Int(interval / 3600))h ago" }
        return "\(Int(interval / 86400))d ago"
    }

    /// Bristol type number (1-7) — public for views.
    func bristolTypeNumber(_ type: Log.PoopType) -> Int {
        switch type {
        case .separateHardLumps: return 1
        case .lumpySausage:      return 2
        case .crackedSausage:    return 3
        case .smoothSausage:     return 4
        case .softBlobs:         return 5
        case .fluffyPieces:      return 6
        case .watery:            return 7
        }
    }

    /// Bristol type human label.
    func bristolTypeLabel(_ type: Log.PoopType) -> String {
        switch type {
        case .separateHardLumps: return "Hard lumps"
        case .lumpySausage:      return "Lumpy sausage"
        case .crackedSausage:    return "Cracked sausage"
        case .smoothSausage:     return "Smooth sausage"
        case .softBlobs:         return "Soft blobs"
        case .fluffyPieces:      return "Fluffy pieces"
        case .watery:            return "Watery"
        }
    }
}
