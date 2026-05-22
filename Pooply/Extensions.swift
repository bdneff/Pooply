//
//  Extensions.swift
//  Pooply
//
//  Created by Brandon Grossnickle on 9/19/25.
//

import Foundation
import SwiftUI
import UIKit

// MARK: - Legacy Design System Aliases (bridge to Theme)

struct AppColors {
    static let background = Theme.Colors.background
    static let backgroundSecondary = Theme.Colors.backgroundSecondary
    static let cardBackground = Theme.Colors.cardBackground

    static let primary = Theme.Colors.primary
    static let secondary = Theme.Colors.skyBlue600
    static let accent = Theme.Colors.skyBlue700

    static let regular = Theme.Colors.good
    static let hard = Theme.Colors.hard
    static let loose = Theme.Colors.loose
    static let bloodAlert = Theme.Colors.blood

    static let hydration = Theme.Colors.hydration
    static let fiber = Theme.Colors.fiber
    static let warning = Theme.Colors.warning
    static let neutral = Theme.Colors.neutral

    static let tealTint = Theme.Colors.tealTint
    static let blueTint = Theme.Colors.blueTint
    static let amberTint = Theme.Colors.amberTint
    static let pinkTint = Theme.Colors.pinkTint

    static let textPrimary = Theme.Colors.textPrimary
    static let textSecondary = Theme.Colors.textSecondary
    static let textTertiary = Theme.Colors.textTertiary

    static let legacyMint = Theme.Colors.mint
    static let legacyLightMint = Theme.Colors.skyBlue50
}

struct AppFonts {
    static func hero(_ size: CGFloat = 48) -> Font { Theme.Fonts.hero(size) }
    static func title(_ size: CGFloat = 28) -> Font { Theme.Fonts.title(size) }
    static func heading(_ size: CGFloat = 20) -> Font { Theme.Fonts.heading(size) }
    static func body(_ size: CGFloat = 16) -> Font { Theme.Fonts.body(size) }
    static func caption(_ size: CGFloat = 14) -> Font { Theme.Fonts.caption(size) }
    static func label(_ size: CGFloat = 12) -> Font { Theme.Fonts.label(size) }
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
    // Standard card shadow — optimized for light warm gray bg
    func cardShadow() -> some View {
        self
            .compositingGroup()
            .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
            .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 1)
    }

    // Floating element shadow (tab bar)
    func floatingShadow() -> some View {
        self
            .compositingGroup()
            .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 8)
            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
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
