//
//  InsightsView.swift
//  Pooply
//
//  Created by Brandon Grossnickle on 9/19/25.
//

import SwiftUI
import Charts

struct InsightsView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @State private var selectedTimeframe = "WEEK"

    var body: some View {
        ZStack {
            Color(hex: "#cff1e5").ignoresSafeArea()
            BlurredBackgroundView()
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        TimeSegmentedToggle(selectedTimeframe: $selectedTimeframe)
                            .fixedSize()
                    }
                    .padding(.horizontal)

                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Log Quality Insights")
                            .font(.custom("Nunito Bold", size: 20))
                            .foregroundStyle(Color(hex: "#1f1f1f"))

                        Text("Track your digestive health patterns over time. This chart shows the daily count of each stool category to help you identify trends and maintain optimal gut health.")
                            .font(.custom("Nunito Regular", size: 16))
                            .foregroundStyle(Color(hex: "#1f1f1f"))
                            .lineSpacing(4)
                    }
                    .padding(.horizontal)

                    // Chart
                    StoolGraphView(selectedTimeframe: selectedTimeframe)
                        .environmentObject(userViewModel)
                        .padding(.horizontal)

                    Spacer(minLength: 100) // Space for floating tab bar
                }
            }
        }
    }
}

struct StoolGraphView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    let selectedTimeframe: String

    private let green = Color(hex: "#19b888")
    private let amber = Color(hex: "#FF7A33")
    private let blue  = Color(hex: "#008CFF")

    private var chartData: [StoolEntry] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        let (start, days, dateFormat) = chartDateRange(for: selectedTimeframe, calendar: cal, today: today)
        let filteredLogs = userViewModel.getLogsForTimeframe(selectedTimeframe)
        let grouped = Dictionary(grouping: filteredLogs.filter { $0.timestamp >= start }) {
            cal.startOfDay(for: $0.timestamp)
        }

        return days.flatMap { day -> [StoolEntry] in
            let logs = grouped[day] ?? []
            let regular = logs.filter { $0.poopScore == .regular }.count
            let hard = logs.filter { $0.poopScore == .hard }.count
            let loose = logs.filter { $0.poopScore == .loose }.count

            return [
                StoolEntry(day: day, type: .regular, count: regular),
                StoolEntry(day: day, type: .hard, count: hard),
                StoolEntry(day: day, type: .loose, count: loose)
            ]
        }
    }

    private func chartDateRange(for timeframe: String, calendar: Calendar, today: Date) -> (start: Date, days: [Date], format: String) {
        switch timeframe {
        case "TODAY":
            return (today, [today], "h a")
        case "WEEK":
            let start = calendar.date(byAdding: .day, value: -6, to: today)!
            let days = (0..<7).compactMap { calendar.date(byAdding: .day, value: -6 + $0, to: today) }
            return (start, days, "E")
        case "MONTH":
            let start = calendar.date(byAdding: .day, value: -29, to: today)!
            let days = (0..<30).compactMap { calendar.date(byAdding: .day, value: -29 + $0, to: today) }
            return (start, days, "d")
        default:
            let start = calendar.date(byAdding: .day, value: -6, to: today)!
            let days = (0..<7).compactMap { calendar.date(byAdding: .day, value: -6 + $0, to: today) }
            return (start, days, "E")
        }
    }
    
    private var yUpperBound: Double {
        let maxCount = chartData.map(\.count).max() ?? 1
        return Double(maxCount) * 1.2
    }
    
    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        let (_, _, dateFormat) = chartDateRange(for: selectedTimeframe, calendar: Calendar.current, today: Calendar.current.startOfDay(for: Date()))
        f.dateFormat = dateFormat
        return f
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Y-axis label above chart
            HStack {
                Text("Daily Count")
                    .font(.custom("Nunito Bold", size: 16))
                    .foregroundStyle(Color(hex: "#1f1f1f"))
                Spacer()
            }

            // Chart with proper padding
            Chart {
                ForEach(chartData) { entry in
                    BarMark(
                        x: .value("Day", dateFormatter.string(from: entry.day)),
                        y: .value("Count", entry.count)
                    )
                    .foregroundStyle(gradient(for: entry.type))
                    .cornerRadius(6, style: .continuous)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color(hex: "#1f1f1f").opacity(0.2))
                    AxisValueLabel()
                        .font(.custom("Nunito Regular", size: 12))
                        .foregroundStyle(Color(hex: "#1f1f1f"))
                }
            }
            .chartXAxis {
                let desiredCount = selectedTimeframe == "MONTH" ? 15 : (selectedTimeframe == "TODAY" ? 1 : 7)
                AxisMarks(values: .automatic(desiredCount: desiredCount)) { _ in
                    AxisValueLabel()
                        .font(.custom("Nunito Regular", size: 12))
                        .foregroundStyle(Color(hex: "#1f1f1f"))
                }
            }
            .chartYScale(domain: 0...yUpperBound)
            .frame(height: 300)
            .padding(.top, 8) // Add padding to prevent cutoff
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: chartData)

            // Legend
            HStack(spacing: 18) {
                LegendDot(color: green, label: "Regular")
                LegendDot(color: amber, label: "Hard")
                LegendDot(color: blue, label: "Loose")
            }
            .font(Font.custom("Nunito Regular", size: 14))
            .foregroundStyle(Color(hex: "#1f1f1f"))
            .padding(.top, 8)
        }
        .padding(20)
        .background(Color(hex: "#e5fff7"))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct StoolEntry: Identifiable, Equatable {
    let id = UUID()
    let day: Date
    let type: StoolType
    let count: Int
}

private enum StoolType: String {
    case regular = "Regular"
    case hard = "Hard"
    case loose = "Loose"
}

private struct StatBlock: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(Font.custom("Nunito Black", size: 32))
                .foregroundStyle(Color.white)
            Text(label)
                .font(Font.custom("Nunito Regular", size: 12))
                .foregroundStyle(Color.white)
                .lineSpacing(2)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Legend

private struct LegendDot: View {
    let color: Color
    let label: String
    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label)
        }
    }
}

private extension StoolGraphView {
    func gradient(for type: StoolType) -> LinearGradient {
        switch type {
        case .regular:
            return LinearGradient(colors: [green, green.opacity(0.6)], startPoint: .top, endPoint: .bottom)
        case .hard:
            return LinearGradient(colors: [amber, amber.opacity(0.5)], startPoint: .top, endPoint: .bottom)
        case .loose:
            return LinearGradient(colors: [blue, blue.opacity(0.55)], startPoint: .top, endPoint: .bottom)
        }
    }
}

#Preview {
    InsightsView()
        .environmentObject(
            UserViewModel(
                user: User(
                    name: "Preview User",
                    age: 25,
                    weight: 160,
                    sex: "female"
                ),
                withDummyData: true
            )
        )
}
