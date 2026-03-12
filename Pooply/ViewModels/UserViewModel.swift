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

        if withDummyData {
            // TODO: Remove before release — forces dummy data for screenshots
            self.logHistory = Log.generateDummyData(count: 30)
        } else {
            let savedLogs = UserDefaultsService.shared.loadLogs()
            self.logHistory = savedLogs
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

    // Generate advanced insights
    func generateAdvancedInsights(for timeframe: String) -> [AdvancedInsight] {
        var insights: [AdvancedInsight] = []
        let currentLogs = getLogsForTimeframe(timeframe)
        let previousLogs = getLogsForPreviousPeriod(timeframe)
        let baseline = calculatePersonalBaseline()

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

        let timeframeLabel = timeframe == "TODAY" ? "today" : (timeframe == "WEEK" ? "this week" : "this month")
        let previousLabel = timeframe == "TODAY" ? "yesterday" : (timeframe == "WEEK" ? "last week" : "last month")

        // MARK: - Trend Analysis
        if !previousLogs.isEmpty {
            let currentAvgScore = Double(currentLogs.reduce(0) { $0 + calculatePoopScore(for: $1) }) / Double(currentLogs.count)
            let previousAvgScore = Double(previousLogs.reduce(0) { $0 + calculatePoopScore(for: $1) }) / Double(previousLogs.count)

            let percentChange = previousAvgScore > 0 ? ((currentAvgScore - previousAvgScore) / previousAvgScore) * 100 : 0
            let isImproved = percentChange > 5

            if abs(percentChange) > 5 {
                insights.append(AdvancedInsight(
                    type: .trend,
                    priority: isImproved ? .medium : .high,
                    icon: isImproved ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill",
                    iconColor: isImproved ? Theme.Colors.green : Theme.Colors.orange,
                    title: isImproved ? "Gut Health Improving" : "Gut Health Declining",
                    description: "Your average gut score is \(isImproved ? "up" : "down") compared to \(previousLabel).",
                    metric: "\(isImproved ? "↑" : "↓")\(Int(abs(percentChange)))%",
                    actionable: isImproved ? nil : "Consider reviewing your recent diet changes"
                ))
            }

            // Hydration trend
            let currentHydration = averageHydrationPercentage(for: timeframe)
            let prevHydrationLogs = previousLogs.compactMap { $0.hydrationPercentage }
            let previousHydration = prevHydrationLogs.isEmpty ? 0 : CGFloat(prevHydrationLogs.reduce(0, +) / Double(prevHydrationLogs.count))

            let hydrationChange = previousHydration > 0 ? ((currentHydration - previousHydration) / previousHydration) * 100 : 0
            if abs(hydrationChange) > 10 {
                let isHydrationUp = hydrationChange > 0
                insights.append(AdvancedInsight(
                    type: .trend,
                    priority: .medium,
                    icon: "drop.fill",
                    iconColor: Theme.Colors.blue,
                    title: isHydrationUp ? "Hydration Improved" : "Hydration Decreased",
                    description: "Your hydration levels are \(isHydrationUp ? "higher" : "lower") than \(previousLabel).",
                    metric: "\(isHydrationUp ? "↑" : "↓")\(Int(abs(hydrationChange)))%",
                    actionable: isHydrationUp ? nil : "Try to drink more water throughout the day"
                ))
            }
        }

        // MARK: - Frequency Patterns
        let calendar = Calendar.current
        let uniqueDays = Set(currentLogs.map { calendar.startOfDay(for: $0.timestamp) })
        let logsPerDay = uniqueDays.isEmpty ? 0 : Double(currentLogs.count) / Double(uniqueDays.count)

        if logsPerDay > 0 {
            let frequencyStatus: String
            let priority: InsightPriority
            let actionable: String?

            if logsPerDay >= 1 && logsPerDay <= 3 {
                frequencyStatus = "healthy"
                priority = .low
                actionable = nil
            } else if logsPerDay < 1 {
                frequencyStatus = "low"
                priority = .high
                actionable = "Increase fiber intake and stay hydrated"
            } else {
                frequencyStatus = "high"
                priority = .medium
                actionable = "Monitor for any digestive issues"
            }

            insights.append(AdvancedInsight(
                type: .frequency,
                priority: priority,
                icon: "chart.bar.fill",
                iconColor: frequencyStatus == "healthy" ? Theme.Colors.green : Theme.Colors.orange,
                title: "Daily Frequency",
                description: "You average \(String(format: "%.1f", logsPerDay)) bowel movements per day \(timeframeLabel).",
                metric: String(format: "%.1f/day", logsPerDay),
                actionable: actionable
            ))
        }

        // MARK: - Time-of-Day Pattern
        if currentLogs.count >= 5 {
            let timeDistribution = getTimeOfDayDistribution(for: timeframe)
            if let peakTime = timeDistribution.max(by: { $0.value < $1.value }), peakTime.value > 0 {
                let totalLogs = timeDistribution.values.reduce(0, +)
                let percentage = totalLogs > 0 ? Int((Double(peakTime.value) / Double(totalLogs)) * 100) : 0

                if percentage >= 40 {
                    insights.append(AdvancedInsight(
                        type: .pattern,
                        priority: .low,
                        icon: "clock.fill",
                        iconColor: Theme.Colors.primary,
                        title: "\(peakTime.key) Pattern",
                        description: "\(percentage)% of your bowel movements occur in the \(peakTime.key.lowercased()).",
                        metric: "\(percentage)%",
                        actionable: nil
                    ))
                }
            }
        }

        // MARK: - Day-of-Week Pattern
        if timeframe != "TODAY" && currentLogs.count >= 7 {
            let dayDistribution = getDayOfWeekDistribution(for: timeframe)
            let avgPerDay = Double(currentLogs.count) / 7.0

            // Find irregular days (significantly above or below average)
            let irregularDays = dayDistribution.filter { Double($0.value) < avgPerDay * 0.5 && avgPerDay > 1 }
            if let lowDay = irregularDays.min(by: { $0.value < $1.value }) {
                insights.append(AdvancedInsight(
                    type: .pattern,
                    priority: .low,
                    icon: "calendar",
                    iconColor: Theme.Colors.textSecondary,
                    title: "Weekly Pattern",
                    description: "\(lowDay.key)s tend to have fewer bowel movements than other days.",
                    metric: nil,
                    actionable: "Consider if your routine changes on this day"
                ))
            }
        }

        // MARK: - Anomaly Detection
        // Blood anomaly
        let logsWithBlood = currentLogs.filter { $0.bloodPercentage > 0 }
        if !logsWithBlood.isEmpty {
            let bloodPercentage = (Double(logsWithBlood.count) / Double(currentLogs.count)) * 100

            insights.append(AdvancedInsight(
                type: .anomaly,
                priority: bloodPercentage > 10 ? .critical : .high,
                icon: "exclamationmark.triangle.fill",
                iconColor: Theme.Colors.red,
                title: "Blood Detected",
                description: "Blood was present in \(logsWithBlood.count) of \(currentLogs.count) logs \(timeframeLabel).",
                metric: "\(logsWithBlood.count) logs",
                actionable: bloodPercentage > 10 ? "Consult a healthcare provider if this persists" : "Monitor and note any patterns"
            ))
        }

        // Score deviation from baseline
        if baseline.averagePoopScore > 0 && currentLogs.count >= 3 {
            let currentAvgScore = Double(currentLogs.reduce(0) { $0 + calculatePoopScore(for: $1) }) / Double(currentLogs.count)
            let deviation = ((currentAvgScore - baseline.averagePoopScore) / baseline.averagePoopScore) * 100

            if deviation < -25 {
                insights.append(AdvancedInsight(
                    type: .anomaly,
                    priority: .high,
                    icon: "exclamationmark.circle.fill",
                    iconColor: Theme.Colors.orange,
                    title: "Below Your Baseline",
                    description: "Your gut score is significantly lower than your personal average.",
                    metric: "↓\(Int(abs(deviation)))%",
                    actionable: "Review any recent diet or lifestyle changes"
                ))
            }
        }

        // MARK: - Recommendations
        // Fiber recommendation
        let avgFiber = averageFiberPercentage(for: timeframe)
        if avgFiber < 0.4 {
            insights.append(AdvancedInsight(
                type: .recommendation,
                priority: .medium,
                icon: "leaf.fill",
                iconColor: Theme.Colors.green,
                title: "Increase Fiber Intake",
                description: "Your fiber levels are low at \(Int(avgFiber * 100))%. Adding more vegetables, fruits, and whole grains can improve regularity.",
                metric: "\(Int(avgFiber * 100))%",
                actionable: "Try adding a serving of vegetables to each meal"
            ))
        }

        // Hydration recommendation
        let avgHydration = averageHydrationPercentage(for: timeframe)
        if avgHydration < 0.5 {
            insights.append(AdvancedInsight(
                type: .recommendation,
                priority: .medium,
                icon: "drop.triangle.fill",
                iconColor: Theme.Colors.blue,
                title: "Boost Hydration",
                description: "Your hydration is at \(Int(avgHydration * 100))%. Proper hydration is essential for healthy digestion.",
                metric: "\(Int(avgHydration * 100))%",
                actionable: "Aim for 8 glasses of water daily"
            ))
        }

        // MARK: - Milestones
        // Streak milestone
        if regularStreak >= 3 {
            insights.append(AdvancedInsight(
                type: .milestone,
                priority: .low,
                icon: "flame.fill",
                iconColor: Theme.Colors.orange,
                title: "\(regularStreak)-Day Regular Streak!",
                description: "You've had \(regularStreak) consecutive regular bowel movements. Keep it up!",
                metric: "🔥 \(regularStreak)",
                actionable: nil
            ))
        }

        // Log count milestone
        let totalLogs = logHistory.count
        let milestones = [10, 25, 50, 100, 250, 500]
        if let reachedMilestone = milestones.filter({ totalLogs >= $0 }).last {
            if totalLogs == reachedMilestone || (totalLogs - reachedMilestone) < 3 {
                insights.append(AdvancedInsight(
                    type: .milestone,
                    priority: .low,
                    icon: "star.fill",
                    iconColor: Theme.Colors.yellow,
                    title: "\(reachedMilestone) Logs Milestone!",
                    description: "You've logged \(totalLogs) bowel movements. Great commitment to tracking your health!",
                    metric: "⭐ \(totalLogs)",
                    actionable: nil
                ))
            }
        }

        // Sort by priority (highest first)
        return insights.sorted { $0.priority > $1.priority }
    }
}
