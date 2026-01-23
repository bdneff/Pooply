//
//  CalendarView.swift
//  Pooply
//
//  Created by Brandon Grossnickle on 9/19/25.
//

import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var userViewModel: UserViewModel

    @State private var selectedMonth: Date = .currentMonth
    @State private var isNextMonth = false
    @State var selectedDate: Date = .now
    
    var safeArea: EdgeInsets
    
    var weekLabelHeight: CGFloat {
        return 30.0
    }
    
    var calendarHeight: CGFloat {
        return calendarTitleViewHeight + calendarGridHeight + weekLabelHeight + topPadding + bottomPadding + safeArea.top
    }
    
    var calendarGridHeight: CGFloat {
        return CGFloat(selectedMonthDates.count / 7) * 50
    }

    
    var calendarTitleViewHeight: CGFloat {
        return 75.0
    }

    var topPadding: CGFloat {
        return 15.0
    }

    var bottomPadding: CGFloat {
        return 15.0
    }

    
    var horizontalPadding: CGFloat {
        return 15.0
    }
    
    var currentMonth: String {
        return format("MMM")
    }
    
    var year: String {
        return format("YYYY")
    }
    
    var monthProgress: CGFloat {
        let calendar = Calendar.current
        if let index = selectedMonthDates.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: selectedDate) }) {
            return CGFloat(index / 7 ).rounded()
        }
        
        return 1.0
    }
    
    var logsForSelectedMonth: [Log] {
        let calendar = Calendar.current
        return userViewModel.logHistory.filter { log in
            calendar.isDate(log.timestamp, equalTo: selectedMonth, toGranularity: .month)
        }
    }
    
    var groupedLogsByDay: [[Log]] {
        let calendar = Calendar.current
        let logs = logsForSelectedMonth.sorted(by: { $0.timestamp < $1.timestamp })
        
        return Dictionary(grouping: logs) { log in
            calendar.startOfDay(for: log.timestamp)
        }
        .sorted(by: { $0.key < $1.key }) // Sort by day
        .map { $0.value }
    }
    
    var body: some View {
        let maxHeight = calendarHeight - (calendarTitleViewHeight + weekLabelHeight + safeArea.top + 50 + topPadding + bottomPadding - 50)

        ZStack {
            Color.pooplyBeige.ignoresSafeArea()
            VStack(spacing: 0) {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        CalendarTestView()
                        LogList()
                            .padding()
                    }
                }
            }
            .background(Color(.pooplyBeige))
            .scrollTargetBehavior(CustomScrollBehavior(maxHeight: maxHeight))
        }
    }
    
    func monthUpdate(_ increment: Bool) {
        let calendar = Calendar.current
        guard let month = calendar.date(byAdding: .month, value: increment ? 1 : -1, to: selectedMonth ) else { return }
        isNextMonth = increment
        withAnimation {
            selectedMonth = month
        }
    }
    
    var selectedMonthDates: [TempDay] {
        return extractDates(selectedMonth)
    }
    
    func format(_ format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: selectedMonth )
    }
    
    @ViewBuilder
    func CalendarTestView() -> some View {
        GeometryReader {
            let size = $0.size
            let minY = $0.frame(in: .scrollView(axis: .vertical)).minY
            let maxHeight = size.height - (calendarTitleViewHeight + weekLabelHeight + safeArea.top + 50 + topPadding + bottomPadding - 50)
            let progress = max(min((-minY / maxHeight), 1), 0)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(currentMonth)
                    .font(Font.custom("Nunito Bold", size: 36 - (10 * progress)))
                    .foregroundStyle(Color.black)
                    .contentTransition(.numericText())
                    .offset(y: -50 * progress)
                    .frame(maxHeight: .infinity, alignment: . bottom)
                    .frame(height: calendarTitleViewHeight)
                    .overlay(alignment: .topLeading) {
                        GeometryReader {
                            let size = $0.size
                            Text(year)
                                .font(Font.custom("Nunito Bold", size: 20 - (5 * progress)))
                                .foregroundStyle(Color.black)
                                .offset(x: (size.width + 5) * progress, y: progress * 3)
                                .contentTransition(.numericText())
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .overlay(alignment: .topTrailing) {
                        HStack(spacing: 24) {
                            Button(action: { monthUpdate(false) }) {
                                Image(systemName: "chevron.left").resizable().aspectRatio(contentMode: .fit).frame(width: 20, height: 24)
                                    .foregroundStyle(Color.black).bold()
                            }
                            //.contentShape(.rect)
                            Button(action: { monthUpdate(true) }) {
                                Image(systemName: "chevron.right").resizable().aspectRatio(contentMode: .fit).frame(width: 20, height: 24).foregroundStyle(Color.black).bold()
                            }
                            //.contentShape(.rect)
                        }
                        .offset(x: 150 * progress)
                    }
                    .frame(height: calendarTitleViewHeight)
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        ForEach(Calendar.current.weekdaySymbols, id: \.self) { symbol in
                            Text(symbol.prefix(3))
                                .font(Font.custom("Nunito Bold", size: 16))
                                .frame(maxWidth: .infinity)
                                .foregroundStyle(.black)
                        }
                    }
                    .frame(height: weekLabelHeight, alignment: .bottom)
                    DaysView(progress: progress)
                        .background(Color(.pooplyBeige))
                        .frame(height: calendarGridHeight - ((calendarGridHeight - 50) * progress), alignment: .top)
                        .offset(y: (monthProgress * -50) * progress)
                        .contentShape(.rect)
                        .clipped()
                        .animation(.linear, value: selectedMonth)
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: isNextMonth ? .trailing : .leading),
                                removal:   .move(edge: isNextMonth ? .leading  : .trailing)
                            )
                        )
                        .id(selectedMonth)
                    
                }
                .offset(y: progress * -50)
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.top, topPadding)
            .padding(.top, safeArea.top)
            .padding(.bottom, bottomPadding)
            .background(Color(.pooplyBeige))
            .frame(maxHeight: .infinity)
            .frame(height: size.height - (maxHeight * progress), alignment: .top)
            .clipped()
            .contentShape(.rect)
            .offset(y: -minY)
        }
        .frame(height: calendarHeight)
        .ignoresSafeArea()
        .zIndex(999)
    }
    
    
    @ViewBuilder
    func DaysView(progress: CGFloat) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(spacing: 0), count: 7), spacing: 0) {
            ForEach(selectedMonthDates) { day in
                Text(day.shortSymbol)
                    .font(Font.custom("Nunito", size: 20))
                    .foregroundStyle(day.ignored ? .clear : .black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .overlay(alignment: .bottom) {
                        Circle().fill(Color.black).frame(width: 5, height: 5).opacity(Calendar.current.isDate(day.date, inSameDayAs: selectedDate) ? 1 : 0).offset(y: progress * -2)
                    }
                    .contentShape(.rect)
                    .onTapGesture {
                        selectedDate = day.date
                    }
            }
        }
    }
    
    @ViewBuilder
    func LogList() -> some View {
        VStack(spacing: 16) {
            ForEach(Array(groupedLogsByDay.enumerated()), id: \.offset) { index, logs in
                LogCard(logs: logs)
                    .transition(.scale)
                    .animation(
                        .ripple(index: index),
                        value: selectedMonth
                    )
            }
            Spacer(minLength: 240)
        }
    }
    
    @ViewBuilder
    func LogCard(logs: [Log]) -> some View {

        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                // Date header only once
                HStack(spacing: 4) {
                    Text(logs.first?.weekday ?? "")
                        .foregroundStyle(.black)
                        .font(Font.custom("Nunito Bold", size: 16))
                    Text(logs.first?.dateString ?? "")
                        .foregroundStyle(.black)
                        .font(Font.custom("Nunito", size: 16))
                    Spacer()
                }
                .padding(8.0)
                .background(Color(.pooplyBeige))
                
                // List all notes
                ForEach(logs) { log in
                    Text(log.analysis)
                        .foregroundStyle(.black)
                        .font(Font.custom("Nunito", size: 16))
                        .padding(4.0)
                }
            }
            .background(Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 16.0, style: .continuous))
            .padding(8.0)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16.0, style: .continuous))
    }
}

struct DateValue: Identifiable {
    var id = UUID().uuidString
    var day: Int
    var date: Date
}

struct CustomScrollBehavior: ScrollTargetBehavior {
    var maxHeight: CGFloat
    func updateTarget(_ target: inout ScrollTarget, context: TargetContext) {
        if target.rect.minY < maxHeight {
            target.rect = .zero
        }
    }
}

#Preview {
    CalendarView(safeArea: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
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

