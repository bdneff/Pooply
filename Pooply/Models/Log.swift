//
//  Model.swift
//  Pooply
//
//  Created by Brandon Grossnickle on 4/4/25.
//

import Foundation

struct Log: Identifiable, Hashable, Codable {

    enum PoopType: String, Codable, CaseIterable {
        case separateHardLumps     // Type 1
        case lumpySausage          // Type 2
        case crackedSausage        // Type 3
        case smoothSausage         // Type 4
        case softBlobs             // Type 5
        case fluffyPieces          // Type 6
        case watery                // Type 7
    }

    enum PoopCategory: String, Codable {
        case regular, loose, hard
    }

    enum PoopColor: String, Codable {
        case lightBrown, mediumBrown, darkBrown, green, yellow, black, red
    }

    enum PoopSize: String, Codable {
        case small, medium, large
    }

    var id: UUID
    var poopScore: PoopCategory
    var type: PoopType
    var color: PoopColor
    var size: PoopSize

    var bloodPercentage: Double // 0.0 to 1.0 (0% to 100%)
    var hydrationPercentage: Double? // Optional - filled by AI analysis
    var fiberPercentage: Double? // Optional - filled by AI analysis

    var timestamp: Date
    var analysis: String
    var imageURL: String?
    var isManualEntry: Bool

    init(
        id: UUID = UUID(),
        poopScore: PoopCategory,
        type: PoopType,
        color: PoopColor,
        size: PoopSize,
        bloodPercentage: Double,
        hydrationPercentage: Double? = nil,
        fiberPercentage: Double? = nil,
        timestamp: Date,
        analysis: String,
        imageURL: String? = nil,
        isManualEntry: Bool = true
    ) {
        self.id = id
        self.poopScore = poopScore
        self.type = type
        self.color = color
        self.size = size
        self.bloodPercentage = bloodPercentage
        self.hydrationPercentage = hydrationPercentage
        self.fiberPercentage = fiberPercentage
        self.timestamp = timestamp
        self.analysis = analysis
        self.imageURL = imageURL
        self.isManualEntry = isManualEntry
    }

    // Custom decoder so existing UserDefaults data (without new fields) still decodes
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        poopScore = try container.decode(PoopCategory.self, forKey: .poopScore)
        type = try container.decode(PoopType.self, forKey: .type)
        color = try container.decode(PoopColor.self, forKey: .color)
        size = try container.decode(PoopSize.self, forKey: .size)
        bloodPercentage = try container.decode(Double.self, forKey: .bloodPercentage)
        hydrationPercentage = try container.decodeIfPresent(Double.self, forKey: .hydrationPercentage)
        fiberPercentage = try container.decodeIfPresent(Double.self, forKey: .fiberPercentage)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        analysis = try container.decode(String.self, forKey: .analysis)
        imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL)
        isManualEntry = try container.decodeIfPresent(Bool.self, forKey: .isManualEntry) ?? true
    }
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d" // e.g., "Sep 19"
        return formatter.string(from: timestamp)
    }
    
    var weekday: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE" // full day name, e.g. Monday
        return formatter.string(from: timestamp)
    }
}


struct Day: Identifiable {
    var id: UUID = .init()
    var shortSymbol: String
    var date: Date
    var ignored: Bool = false
}

struct TempDay: Identifiable {
    var id: UUID = .init()
    var shortSymbol: String
    var date: Date
    var ignored: Bool = false
}

extension Log {
    /// Screenshot-ready dummy data with a clear improvement arc.
    ///
    /// The 30-day window is broken into four chapters so charts read as
    /// "trending up":
    ///   • Days 0–6   (this week)   — locked-in: 100% regular, fiber & hydration peak.
    ///                                Drives a clean 7+ day streak.
    ///   • Days 7–13  (last week)   — strong: ~90% regular, scores climbing.
    ///   • Days 14–21 (week 3)      — improving: ~70% regular, mid-range scores.
    ///   • Days 22–29 (week 4, oldest) — rough baseline: ~50% regular, sparser logs.
    ///
    /// `count` is interpreted as the number of DAYS to cover, not raw log count.
    /// Multiple logs are added per day to give the frequency graph variation.
    static func generateDummyData(count: Int = 30) -> [Log] {
        let calendar = Calendar.current
        let now = Date()

        let healthyTypes: [PoopType] = [.smoothSausage, .crackedSausage]
        let okTypes:      [PoopType] = [.softBlobs, .lumpySausage]
        let offTypes:     [PoopType] = [.lumpySausage, .fluffyPieces, .separateHardLumps]
        let goodColors:   [PoopColor] = [.mediumBrown, .mediumBrown, .darkBrown, .lightBrown]
        let okColors:     [PoopColor] = [.mediumBrown, .darkBrown, .lightBrown, .yellow]

        let goodAnalyses = [
            "Healthy stool — great hydration and fiber balance. Keep it up!",
            "Textbook form. Your gut is dialed in.",
            "Excellent color and consistency. Hydration looks optimal.",
            "Smooth and well-formed. Diet is supporting strong digestion.",
            "Great log — fiber and hydration both strong.",
            "Consistent with your improving trend. Nice work."
        ]
        let okAnalyses = [
            "Slightly softer than ideal. A bit more fiber would help.",
            "A touch firmer than usual — try a glass more water today.",
            "Decent log. A few small tweaks could push this into the green.",
            "Normal range, but not your best. Monitor over the week."
        ]

        struct DayPlan {
            let logsToday: Int
            let regularRate: Double
            let hydration: ClosedRange<Double>
            let fiber: ClosedRange<Double>
            let useGoodColor: Bool
        }

        // Vary logs/day across the week so the frequency graph isn't flat.
        func plan(daysAgo: Int) -> DayPlan {
            switch daysAgo {
            case 0...6:   // recent week — peak
                let logs = [2, 1, 2, 1, 2, 1, 2][daysAgo]
                return DayPlan(logsToday: logs,
                               regularRate: 1.0,
                               hydration: 0.78...0.90,
                               fiber:     0.72...0.84,
                               useGoodColor: true)
            case 7...13:  // last week — strong
                let logs = [2, 1, 2, 2, 1, 2, 1][daysAgo - 7]
                return DayPlan(logsToday: logs,
                               regularRate: 0.90,
                               hydration: 0.66...0.80,
                               fiber:     0.62...0.76,
                               useGoodColor: true)
            case 14...21: // week 3 — improving
                let logs = [1, 2, 1, 1, 2, 1, 1, 2][daysAgo - 14]
                return DayPlan(logsToday: logs,
                               regularRate: 0.70,
                               hydration: 0.55...0.68,
                               fiber:     0.50...0.64,
                               useGoodColor: false)
            default:      // 22+ — oldest, rougher baseline
                let logs = [1, 1, 0, 1, 1, 0, 1, 1][min(daysAgo - 22, 7)]
                return DayPlan(logsToday: logs,
                               regularRate: 0.50,
                               hydration: 0.42...0.56,
                               fiber:     0.40...0.55,
                               useGoodColor: false)
            }
        }

        var results = [Log]()

        for daysAgo in 0..<count {
            let p = plan(daysAgo: daysAgo)
            guard p.logsToday > 0,
                  let date = calendar.date(byAdding: .day, value: -daysAgo, to: now)
            else { continue }

            for logIndex in 0..<p.logsToday {
                // Realistic times-of-day: morning first, then afternoon/evening.
                let hour: Int
                switch logIndex {
                case 0: hour = Int.random(in: 7...10)    // morning
                case 1: hour = Int.random(in: 14...18)   // afternoon/evening
                default: hour = Int.random(in: 19...21)  // night
                }
                let minute = Int.random(in: 0...59)
                guard let logDate = calendar.date(bySettingHour: hour,
                                                  minute: minute,
                                                  second: 0,
                                                  of: date)
                else { continue }

                let isRegular = Double.random(in: 0...1) < p.regularRate
                let type: PoopType = isRegular
                    ? healthyTypes.randomElement()!
                    : (Double.random(in: 0...1) < 0.6
                        ? okTypes.randomElement()!
                        : offTypes.randomElement()!)

                let color = p.useGoodColor
                    ? goodColors.randomElement()!
                    : okColors.randomElement()!

                let analysis = isRegular
                    ? goodAnalyses.randomElement()!
                    : okAnalyses.randomElement()!

                let log = Log(
                    poopScore: categorizePoopType(type),
                    type: type,
                    color: color,
                    size: [PoopSize.medium, .medium, .large, .medium].randomElement()!,
                    bloodPercentage: 0.0,
                    hydrationPercentage: Double.random(in: p.hydration),
                    fiberPercentage: Double.random(in: p.fiber),
                    timestamp: logDate,
                    analysis: analysis
                )
                results.append(log)
            }
        }

        return results
    }

    static func categorizePoopType(_ type: PoopType) -> PoopCategory {
        switch type {
        case .crackedSausage, .smoothSausage:
            return .regular  // Types 3, 4
        case .softBlobs, .fluffyPieces, .watery:
            return .loose    // Types 5, 6, 7
        case .separateHardLumps, .lumpySausage:
            return .hard     // Types 1, 2
        }
    }
}
