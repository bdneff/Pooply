//
//  Home.swift
//  Pooply
//
//  Created by Brandon Grossnickle on 9/9/25.
//

import SwiftUI

struct BlurredBackgroundView: View {
    var body: some View {
        VStack {
            Circle()
                .fill(Color(hex: "#19b888").opacity(0.64))
                .offset(x: 200, y: -500)
                .blur(radius: 200)
        }
    }
}

struct HomeView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @Binding var showCameraView: Bool
    @Binding var showManualEntry: Bool
    @State private var showDayLogsModal = false
    @State private var selectedTimeframe = "TODAY"

    // CALENDAR
    @State private var selectedMonth: Date = .currentMonth
    @State private var isNextMonth = false
    @State var selectedDate: Date = .now
    
    var selectedMonthDates: [TempDay] {
        return extractDates(selectedMonth)
    }
    
    var body: some View {
        ZStack {
            // Mint background
            Color(hex: "#cff1e5").ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 8) {
//                    HStack {
//                        Spacer()
//                        Button(action: {}) {
//                            Image(systemName: "person.fill")
//                                .font(.system(size: 24, weight: .medium))
//                                .foregroundColor(.white)
//                                .padding(12)
//                                .background(Color(hex: "#19b888"))
//                                .clipShape(Circle())
//                        }
//                        .frame(width: 44, height: 44)
//                    }
//                    .padding(.horizontal)
                    HStack(alignment: .top) {
                        VStack(alignment: .center, spacing: 0) {
                            Text(userViewModel.timeBasedGreeting)
                                .font(Font.custom("Nunito Bold", size: 24))
                                .foregroundStyle(Color(hex: "#1B5E20"))
                                .frame(maxWidth: .infinity, alignment: .center)

                            let description = userViewModel.lastLogDescription()
                            let parts = description.components(separatedBy: ": ")
                            if parts.count == 2 {
                                (Text(parts[0] + ": ")
                                    .font(Font.custom("Nunito Regular", size: 16))
                                    .foregroundStyle(Color(hex: "#2E7D32")) +
                                Text(parts[1])
                                    .font(Font.custom("Nunito Bold", size: 16))
                                    .foregroundStyle(Color(hex: "#1B5E20")))
                                    .frame(maxWidth: .infinity, alignment: .center)
                            } else {
                                Text(description)
                                    .font(Font.custom("Nunito Regular", size: 16))
                                    .foregroundStyle(Color(hex: "#2E7D32"))
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                        }
                    }
                    .padding(.horizontal)
                    VStack(spacing: 24) {
                        TimeSegmentedToggle(selectedTimeframe: $selectedTimeframe)
                        VStack(spacing: 0) {
                            VStack(alignment: .center, spacing: 0) {
                                GutHealthGauge(timeframe: selectedTimeframe)
                            }
                            HStack(spacing: 16) {
                                HydrationGauge(timeframe: selectedTimeframe)
                                    .frame(maxWidth: .infinity)
                                BloodGauge(timeframe: selectedTimeframe)
                                    .frame(maxWidth: .infinity)
                                FiberGauge(timeframe: selectedTimeframe)
                                    .frame(maxWidth: .infinity)
                            }
                            .offset(y: -24)
                        }
                    }
                    .padding(.horizontal)

                    LogCalendar()
                        .padding()
                        .background(Color(hex: "#e5fff7"))
                        .clipShape(RoundedRectangle(cornerRadius: 32.0, style: .continuous))
                        .padding(.horizontal)

                    // Recent Logs Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Recent Logs")
                            .font(Font.custom("Nunito Bold", size: 20))
                            .foregroundStyle(Color(hex: "#1B5E20"))
                            .padding(.horizontal)

                        LazyVStack(spacing: 12) {
                            ForEach(Array(userViewModel.recentLogs.prefix(5)), id: \.id) { log in
                                LogCard(log: log)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, 24)
            }
        }
        .sheet(isPresented: $showDayLogsModal) {
            DayLogsModal(selectedDate: selectedDate, isPresented: $showDayLogsModal)
        }
    }

    @ViewBuilder
    private func streakBlock(imageName: String, title: String, value: String) -> some View {
        VStack(alignment: .center, spacing: 2) {
            HStack {
                Image(systemName: imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .symbolRenderingMode(.multicolor)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "#FFB84C"), Color.red.opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                Text(value)
                    .font(Font.custom("Nunito Bold", size: 24))
                    .foregroundStyle(Color(hex: "#1B5E20"))
            }
            Text(title)
                .font(Font.custom("Nunito Regular", size: 12))
                .foregroundStyle(Color(hex: "#1B5E20"))
                .lineSpacing(2)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    func LogCalendar() -> some View {
        VStack(spacing: 22) {
            HStack(spacing: 0) {
                streakBlock(imageName: "flame.fill", title: "CURRENT STREAK", value: "\(userViewModel.regularStreak)")
                streakBlock(imageName: "trophy.fill", title: "LONGEST STREAK", value: "\(userViewModel.longestRegularStreak)")
            }
            HStack {
                Button(action: { monthUpdate(false) }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color(hex: "#1B5E20"))
                }

                Spacer()

                HStack(spacing: 2) {
                    Text(format("MMMM").uppercased())
                        .font(.custom("Nunito Bold", size: 16))
                        .foregroundStyle(Color(hex: "#1B5E20"))
                    Text(format("YYYY"))
                        .font(.custom("Nunito Bold", size: 16))
                        .foregroundStyle(Color(hex: "#1B5E20"))
                }

                Spacer()

                Button(action: { monthUpdate(true) }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color(hex: "#1B5E20"))
                }
            }
            .padding(.horizontal, 4)

            // ─── Weekday labels ───────────────
            HStack {
                ForEach(Calendar.current.shortWeekdaySymbols, id: \.self) { symbol in
                    Text(symbol.uppercased())
                        .font(.custom("Nunito Bold", size: 14))
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(Color(hex: "#1B5E20").opacity(0.7))
                }
            }
            LazyVGrid(columns: Array(repeating: GridItem(spacing: 10), count: 7), spacing: 10) {
                ForEach(selectedMonthDates) { day in
                    if day.ignored {
                        Color.clear.frame(height: 44)
                    } else {
                        let hasRegularPoops = userViewModel.dayHasRegularPoops(day.date)
                        let isToday = Calendar.current.isDateInToday(day.date)
                        let isSelected = Calendar.current.isDate(day.date, inSameDayAs: selectedDate)
                        let baseColor = Color.white.opacity(0.08)

                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(baseColor)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(hasRegularPoops ? Color(hex: "#19b888").opacity(0.64) : Color.clear)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(
                                            isToday ? Color(hex: "#19b888").opacity(0.55) : .clear,
                                            lineWidth: 1.6
                                        )
                                        .shadow(color: isToday ? Color(hex: "#19b888").opacity(0.35) : .clear,
                                                radius: 6, y: 0)
                                )

                            Text("\(Calendar.current.component(.day, from: day.date))")
                                .font(.custom("Nunito Black", size: 18))
                                .foregroundStyle(Color(hex: "#1B5E20"))
                        }
                        .frame(height: 44)
                        .scaleEffect(isSelected ? 1.05 : 1.0)
                        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedDate)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                selectedDate = day.date
                                showDayLogsModal = true
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 6)
        }
    }
    
    private func monthUpdate(_ increment: Bool) {
        let calendar = Calendar.current
        guard let month = calendar.date(byAdding: .month, value: increment ? 1 : -1, to: selectedMonth ) else { return }
        isNextMonth = increment
        withAnimation {
            selectedMonth = month
        }
    }
    

    private func format(_ format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: selectedMonth )
    }

    @ViewBuilder
    func HydrationGauge(timeframe: String) -> some View {
        let progress: CGFloat = userViewModel.averageHydrationPercentage(for: timeframe)
        let size: CGFloat = 64
        let lineWidth: CGFloat = 2
        
        VStack {
            ZStack {
                // Background track
                Circle()
                    .stroke(Color(hex: "#1f1f1f").opacity(0.2), lineWidth: lineWidth)
                
                // Progress ring
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color(hex: "#1f1f1f"), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90)) // start at top
                
                // Water drop behind the text
                Image("water")
                    .resizable()
                    .scaledToFit()
                    .symbolRenderingMode(.multicolor)
                    .opacity(0.64)
                    .frame(width: 32, height: 32)
                
                HStack(alignment: .center, spacing: 0) {
                    Text("\(Int(progress * 100))")
                        .font(Font.custom("Nunito Bold", size: 20))
                        .foregroundStyle(Color(hex: "#1B5E20"))
                        .contentTransition(.numericText())
                    Text("%")
                        .font(Font.custom("Nunito Regular", size: 12))
                        .foregroundStyle(Color(hex: "#1B5E20"))
                }
            }
            .frame(width: size, height: size)
            Text("HYDRATION")
                .font(Font.custom("Nunito Regular", size: 12))
                .foregroundStyle(Color(hex: "#1B5E20"))
        }
    }
    
    @ViewBuilder
    func BloodGauge(timeframe: String) -> some View {
        let progress: CGFloat = userViewModel.averageBloodPercentage(for: timeframe)
        let size: CGFloat = 64
        let lineWidth: CGFloat = 2
        
        VStack {
            ZStack {
                // Background track
                Circle()
                    .stroke(Color(hex: "#1f1f1f").opacity(0.2), lineWidth: lineWidth)
                
                // Progress ring
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color(hex: "#1f1f1f"), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90)) // start at top
                
                // Water drop behind the text
                Image("blood")
                    .resizable()
                    .scaledToFit()
                    .symbolRenderingMode(.multicolor)
                    .opacity(0.64)
                    .frame(width: 32, height: 32)
                
                HStack(alignment: .center, spacing: 0) {
                    Text("\(Int(progress * 100))")
                        .font(Font.custom("Nunito Bold", size: 20))
                        .foregroundStyle(Color(hex: "#1B5E20"))
                    Text("%")
                        .font(Font.custom("Nunito Regular", size: 12))
                        .foregroundStyle(Color(hex: "#1B5E20"))
                        .contentTransition(.numericText())
                }
            }
            .frame(width: size, height: size)
            Text("BLOOD")
                .font(Font.custom("Nunito Regular", size: 12))
                .foregroundStyle(Color(hex: "#1B5E20"))
        }
    }
    
    @ViewBuilder
    func FiberGauge(timeframe: String) -> some View {
        let progress: CGFloat = userViewModel.averageFiberPercentage(for: timeframe)
        let size: CGFloat = 64
        let lineWidth: CGFloat = 2
        
        VStack {
            ZStack {
                // Background track
                Circle()
                    .stroke(Color(hex: "#1f1f1f").opacity(0.2), lineWidth: lineWidth)
                
                // Progress ring
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color(hex: "#1f1f1f"), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90)) // start at top
                
                // Water drop behind the text
                Image("wheat")
                    .resizable()
                    .scaledToFit()
                    .symbolRenderingMode(.multicolor)
                    .opacity(0.64)
                    .frame(width: 32, height: 32)
                
                HStack(alignment: .center, spacing: 0) {
                    Text("\(Int(progress * 100))")
                        .font(Font.custom("Nunito Bold", size: 20))
                        .foregroundStyle(Color(hex: "#1B5E20"))
                    Text("%")
                        .font(Font.custom("Nunito Regular", size: 12))
                        .foregroundStyle(Color(hex: "#1B5E20"))
                        .contentTransition(.numericText())
                }
            }
            .frame(width: size, height: size)
            Text("FIBER")
                .font(Font.custom("Nunito Regular", size: 12))
                .foregroundStyle(Color(hex: "#1B5E20"))
        }
    }
    
    @ViewBuilder
    func StreaksCard() -> some View {
        
    }

    // MARK: - Helpers (put inside the same View)
    private func dayInfoForIndex(_ i: Int) -> (date: Date, fullName: String, shortLabel: String) {
        let cal = Calendar.current
        let today = Date()
        // Get start of current week (based on locale firstWeekday)
        let startOfWeek = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
        let date = cal.date(byAdding: .day, value: i, to: startOfWeek)!

        let fullFmt = DateFormatter()
        fullFmt.locale = Locale.current
        fullFmt.dateFormat = "EEEE" // "Monday"
        let full = fullFmt.string(from: date)

        // Single-letter label: "S","M","T","W","T","F","S"
        let shortFmt = DateFormatter()
        shortFmt.locale = Locale.current
        shortFmt.dateFormat = "EEEEE"
        let short = shortFmt.string(from: date).uppercased()

        return (date, full, short)
    }

}

struct TimeSegmentedToggle: View {
    @Binding var selectedTimeframe: String
    @Namespace private var animation
    private let options = ["TODAY", "WEEK", "MONTH"]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options, id: \.self) { option in
                ZStack {
                    if selectedTimeframe == option {
                        Capsule()
                            .fill(Color.white)
                            .matchedGeometryEffect(id: "selection", in: animation)
                    } else {
                        Capsule()
                            .fill(Color.gray.opacity(0.08))
                    }

                    Text(option)
                        .font(Font.custom("Nunito Black", size: 14))
                        .foregroundColor(selectedTimeframe == option ? .black : .gray)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 18)
                }
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedTimeframe = option
                    }
                }
            }
        }
        .padding(4)
        .clipShape(RoundedRectangle(cornerRadius: 32.0))
    }
}


struct GutHealthGauge: View {
    let timeframe: String
    @EnvironmentObject var userViewModel: UserViewModel
    @ScaledMetric(relativeTo: .title) private var lineWidth: CGFloat = 14
    @State private var animatedProgress: Double = 0.0
    @State private var animatedPercentage: Double = 0.0

    private var targetProgress: Double {
        let gutHealthPercentage = userViewModel.gutHealthPercentage(for: timeframe)
        return min(max(gutHealthPercentage, 0), 1)
    }

    private var targetPercentage: Double { targetProgress * 100 }

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(colors: [
                        Color(hex: "#19b888").opacity(0.08),
                        .clear
                    ], center: .center, startRadius: 20, endRadius: 80)
                )
                .blur(radius: 20)
            
            // BACKGROUND ARC (gray) — match the same geometry as the progress arc
            ArcShape(startAngle: .degrees(-210), endAngle: .degrees(30))
                .stroke(Color(hex: "#19b888").opacity(0.16),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

            // FOREGROUND ARC (baby blue)
            ArcShape(startAngle: .degrees(-210),
                     endAngle: .degrees(-210 + 240 * animatedProgress))
            .stroke(
                Color(hex: "#19b888").gradient,
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
            )
            .transition(.slide)
            .animation(.linear, value: animatedProgress)

            ZStack {
                VStack(spacing: 8) {
                    HStack(alignment: .center, spacing: 0) {
                        Text("\(Int(animatedPercentage))")
                            .font(Font.custom("Nunito Black", size: 56))
                            .foregroundStyle(Color(hex: "#1B5E20"))
                            .contentTransition(.numericText())
                        Text("%")
                            .font(Font.custom("Nunito Bold", size: 24))
                            .foregroundStyle(Color(hex: "#1B5E20"))
                    }
                    HStack(alignment: .top, spacing: 4) {
                        Button(action: {}) {
                            Text("GUT HEALTH")
                                .font(Font.custom("Nunito Bold", size: 14))
                                .foregroundStyle(Color(hex: "#1B5E20"))
                            Image(systemName: "info.circle")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 12, height: 12)
                                .foregroundStyle(Color(hex: "#1B5E20"))
                        }
                    }
                }
            }
        }
        .frame(width: 180, height: 180)
        .onAppear {
            // Initial animation
            withAnimation(.easeInOut(duration: 1.0)) {
                animatedProgress = targetProgress
                animatedPercentage = targetPercentage
            }
        }
        .onChange(of: targetProgress) { newProgress in
            // Animate when timeframe changes
            withAnimation(.easeInOut(duration: 0.8)) {
                animatedProgress = newProgress
                animatedPercentage = newProgress * 100
            }
        }
        .padding()
    }
}


// MARK: - Arc Shape
struct ArcShape: Shape {
    var startAngle: Angle
    var endAngle: Angle

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(center: CGPoint(x: rect.midX, y: rect.midY),
                    radius: rect.width / 2,
                    startAngle: startAngle,
                    endAngle: endAngle,
                    clockwise: false)
        return path
    }
}

struct DayLogsModal: View {
    let selectedDate: Date
    @Binding var isPresented: Bool
    @EnvironmentObject var userViewModel: UserViewModel

    private var logsForSelectedDay: [Log] {
        let calendar = Calendar.current
        return userViewModel.logHistory.filter {
            calendar.isDate($0.timestamp, inSameDayAs: selectedDate)
        }
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter
    }

    var body: some View {
        ZStack {
            Color(hex: "#cff1e5").ignoresSafeArea()

            VStack {
                // Header
                HStack {
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color(hex: "#1f1f1f"))
                            .frame(width: 20, height: 20)
                            .padding()
                            .background(Color(hex: "#e5fff7"))
                            .clipShape(Circle())
                    }
                    Spacer()
                    Text(dateFormatter.string(from: selectedDate))
                        .font(.custom("Nunito Bold", size: 18))
                        .foregroundColor(Color(hex: "#1f1f1f"))
                    Spacer()
                    // Invisible button for balance
                    Button(action: {}) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.clear)
                            .frame(width: 20, height: 20)
                            .padding()
                    }
                }
                .padding()

                // Content
                if logsForSelectedDay.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 48))
                            .foregroundColor(Color(hex: "#1f1f1f"))
                        Text("No Logs")
                            .font(.custom("Nunito Bold", size: 24))
                            .foregroundColor(Color(hex: "#1f1f1f"))
                        Text("No entries recorded for this day")
                            .font(.custom("Nunito Regular", size: 16))
                            .foregroundColor(Color(hex: "#1f1f1f"))
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(logsForSelectedDay.sorted(by: { $0.timestamp > $1.timestamp }), id: \.id) { log in
                                LogCard(log: log)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
    }
}

#Preview {
    HomeView(showCameraView: .constant(false), showManualEntry: .constant(false))
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
