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
    static func generateDummyData(count: Int = 30) -> [Log] {
        // Generally good data — scores should land in the "barely green" range
        let healthyTypes: [PoopType] = [.smoothSausage, .crackedSausage, .smoothSausage, .crackedSausage]
        let okTypes: [PoopType] = [.softBlobs, .lumpySausage, .fluffyPieces]

        let commonColors: [PoopColor] = [.mediumBrown, .mediumBrown, .darkBrown, .lightBrown]

        let analyses = [
            "Healthy stool — great hydration and fiber balance. Keep it up!",
            "Well-formed and consistent. Your gut is in good shape today.",
            "Slightly softer than ideal. Consider adding more fiber-rich foods.",
            "Excellent form and color. Hydration levels look optimal.",
            "Good consistency. Your digestive system is working well.",
            "A bit firmer than usual — try drinking more water today.",
            "Smooth and well-formed. Your diet is supporting healthy digestion.",
            "Looser than average — could be diet-related. Monitor over next few days.",
            "Great log! Fiber and hydration indicators are both strong.",
            "Normal and healthy. Consistent with your recent trend."
        ]

        var results = [Log]()
        let calendar = Calendar.current

        for i in 0..<count {
            let daysAgo = i  // One log per day going back
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) else { continue }

            // Random time between 6am and 10am for realism
            let hour = Int.random(in: 6...10)
            let minute = Int.random(in: 0...59)
            let logDate = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date)!

            // Mostly healthy, some ok — keeps gauge barely green
            let type: PoopType = Double.random(in: 0...1) < 0.65
                ? healthyTypes.randomElement()!
                : okTypes.randomElement()!

            let color = commonColors.randomElement()!

            let dummy = Log(
                poopScore: categorizePoopType(type),
                type: type,
                color: color,
                size: [PoopSize.medium, .medium, .large].randomElement()!,
                bloodPercentage: 0.0,
                hydrationPercentage: Double.random(in: 0.55...0.75),
                fiberPercentage: Double.random(in: 0.4...0.65),
                timestamp: logDate,
                analysis: analyses[i % analyses.count]
            )
            results.append(dummy)
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
