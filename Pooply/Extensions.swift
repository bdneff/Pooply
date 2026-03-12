//
//  Extensions.swift
//  Pooply
//
//  Created by Brandon Grossnickle on 9/19/25.
//

import Foundation
import SwiftUI
import UIKit

// MARK: - Design System Colors

struct AppColors {
    // Backgrounds
    static let background = Color(hex: "#F1F5EC")
    static let backgroundSecondary = Color(hex: "#F8FAF9")
    static let cardBackground = Color.white

    // Brand Colors
    static let primary = Color(hex: "#19B888")        // Pooply Teal
    static let secondary = Color(hex: "#2E7D32")      // Forest Green
    static let accent = Color(hex: "#1B5E20")         // Dark Forest

    // Category Colors
    static let regular = Color(hex: "#19B888")        // Teal - Good
    static let hard = Color(hex: "#FF7A33")           // Warm Amber
    static let loose = Color(hex: "#008CFF")          // Sky Blue
    static let bloodAlert = Color(hex: "#E53935")     // Red

    // Supporting Colors
    static let hydration = Color(hex: "#4FC3F7")      // Light Blue
    static let fiber = Color(hex: "#FFB74D")          // Warm Yellow
    static let warning = Color(hex: "#FFA726")        // Orange
    static let neutral = Color(hex: "#78909C")        // Gray

    // Card Accent Tints
    static let tealTint = Color(hex: "#E8F5F1")
    static let blueTint = Color(hex: "#E3F2FD")
    static let amberTint = Color(hex: "#FFF3E0")
    static let pinkTint = Color(hex: "#FCE4EC")

    // Text Colors
    static let textPrimary = Color(hex: "#1B5E20")
    static let textSecondary = Color(hex: "#2E7D32")
    static let textTertiary = Color(hex: "#78909C")

    // Legacy (for gradual migration)
    static let legacyMint = Color(hex: "#cff1e5")
    static let legacyLightMint = Color(hex: "#e5fff7")
}

// MARK: - Design System Typography

struct AppFonts {
    static func hero(_ size: CGFloat = 48) -> Font {
        .custom("Nunito-Black", size: size)
    }
    static func title(_ size: CGFloat = 28) -> Font {
        .custom("Nunito-Bold", size: size)
    }
    static func heading(_ size: CGFloat = 20) -> Font {
        .custom("Nunito-Bold", size: size)
    }
    static func body(_ size: CGFloat = 16) -> Font {
        .custom("Nunito-Regular", size: size)
    }
    static func caption(_ size: CGFloat = 14) -> Font {
        .custom("Nunito-Regular", size: size)
    }
    static func label(_ size: CGFloat = 12) -> Font {
        .custom("Nunito-Bold", size: size)
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - View Extensions

extension View {
    // Standard card shadow — compositingGroup reduces offscreen render passes
    func cardShadow() -> some View {
        self
            .compositingGroup()
            .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 6)
    }

    // Floating element shadow (tab bar, FAB)
    func floatingShadow() -> some View {
        self
            .compositingGroup()
            .shadow(color: Color.black.opacity(0.1), radius: 16, x: 0, y: 8)
    }

    // Subtle shadow for inner cards
    func subtleShadow() -> some View {
        self
            .compositingGroup()
            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
    
    func extractDates(_ month: Date) -> [TempDay] {
        var days: [TempDay] = []
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "dd"
        
        guard let range = calendar.range(of: .day, in: .month, for: month)?.compactMap({
            value -> Date? in
            return calendar.date(byAdding: .day, value: value - 1, to: month)
        }) else {
            return days
        }
        
        let firstWeekDay = calendar.component(.weekday, from: range.first!)
        for index in Array(0..<firstWeekDay - 1).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -index - 1, to: range.first!) else { return days }
            let shortSymbol = formatter.string(from: date)
            days.append(.init(shortSymbol: shortSymbol, date: date, ignored: true))
        }
        
        range.forEach { date in
            let shortSymbol = formatter.string(from: date)
            days.append(.init(shortSymbol: shortSymbol, date: date))
        }
        
        let lastWeekDay = 7 - calendar.component(.weekday, from: range.last!)
        if lastWeekDay > 0 {
            for index in 0..<lastWeekDay {
                guard let date = calendar.date(byAdding: .day, value: index + 1, to: range.last!) else { return days }
                let shortSymbol = formatter.string(from: date)
                days.append(.init(shortSymbol: shortSymbol, date: date, ignored: true))
            }
        }
        
        return days
    }
}

typealias UnixTimestamp = Int

extension Date {
    var unixTimestamp: UnixTimestamp {
        return UnixTimestamp(timeIntervalSince1970 * 1_000) // millisecond precision
    }
    
    func getAllDates() -> [Date] {
        let calendar = Calendar.current
        let startDate = calendar.date(from: Calendar.current.dateComponents([.year, .month], from: self))!
        
        // get num days in current month
        let  range = calendar.range(of: .day, in: .month, for: self)!
        
        return range.compactMap { day -> Date in
            return calendar.date(byAdding: .day, value: day - 1, to: startDate)!
        }
    }
    
    func isDateInThisWeek(using calendar: Calendar = .current) -> Bool {
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: Date()) else {
            return false
        }
        return weekInterval.contains(self)
    }
    
    static var currentMonth: Date {
        let calendar = Calendar.current
        guard let currentMonth = calendar.date(from: Calendar.current.dateComponents([.month, .year], from: .now)) else {
            return .now
        }
        return currentMonth
    }
}

// MARK: - UIImage Resize for Analysis

extension UIImage {
    func resizedForAnalysis(maxDimension: CGFloat) -> UIImage {
        let aspect = size.width / size.height
        let newSize: CGSize
        if size.width > size.height {
            newSize = CGSize(width: min(size.width, maxDimension), height: min(size.width, maxDimension) / aspect)
        } else {
            newSize = CGSize(width: min(size.height, maxDimension) * aspect, height: min(size.height, maxDimension))
        }
        guard newSize.width < size.width else { return self }
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

extension Animation {
    static func ripple(index: Int) -> Animation {
        Animation.spring(dampingFraction: 0.5)
            .speed(2)
            .delay(0.03 * Double(index))
    }
}
