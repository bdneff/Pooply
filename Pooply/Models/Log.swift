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

    var id = UUID()
    var poopScore: PoopCategory
    var type: PoopType
    var color: PoopColor
    var size: PoopSize

    var bloodPercentage: Double // 0.0 to 1.0 (0% to 100%)
    var hydrationPercentage: Double? // Optional - filled by AI analysis
    var fiberPercentage: Double? // Optional - filled by AI analysis

    var timestamp: Date
    var analysis: String
    
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
    static func generateDummyData(count: Int = 20) -> [Log] {

        let possibleTypes: [PoopType] = PoopType.allCases
        let possibleColors: [PoopColor] = [
            .lightBrown, .mediumBrown, .darkBrown,
            .green, .yellow, .black, .red
        ]
        let possibleSizes: [PoopSize] = [
            .small, .medium, .large
        ]

        var results = [Log]()

        for i in 1...count {
            let daysAgo = Int.random(in: 0..<20)
            let randomDate = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
            let randomType = possibleTypes.randomElement()!

            let dummy = Log(
                poopScore: categorizePoopType(randomType),
                type: randomType,
                color: possibleColors.randomElement()!,
                size: possibleSizes.randomElement()!,
                bloodPercentage: Double.random(in: 0...0.1), // 0-10% blood
                hydrationPercentage: Double.random(in: 0.5...1.0), // 50-100% hydration
                fiberPercentage: Double.random(in: 0.2...0.8), // 20-80% fiber
                timestamp: randomDate,
                analysis: "Dummy note for sample #\(i)"
            )
            results.append(dummy)
        }

        print(results)
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


// Example usage:
//let dummyAnalyses = PoopAnalysis.generateDummyData()
//print(dummyAnalyses)
