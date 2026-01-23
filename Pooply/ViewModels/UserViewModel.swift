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
    
    init(user: User, withDummyData: Bool = true) {
        self.user = user
        if withDummyData {
            self.logHistory = Log.generateDummyData(count: 50)
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
        let calendar = Calendar.current

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
        // Sort by timestamp to keep most recent first
        logHistory.sort { $0.timestamp > $1.timestamp }
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
}
