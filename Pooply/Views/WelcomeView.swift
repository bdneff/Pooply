//
//  WelcomeView.swift
//  Pooply
//
//  Created by Brandon Grossnickle on 10/29/25.
//

import SwiftUI

struct WelcomeView: View {
    @State private var currentScreen = 0 // 0 = initial, 1 = before, 2 = after
    @State private var animatedText = ""
    @State private var showBeforeCalendar = false
    @State private var showAfterCalendar = false
    @State private var showFixMyGutText = false
    @Binding var isPresented: Bool

    private var buttonText: String {
        switch currentScreen {
        case 0: return "Continue"
        case 1: return "Continue"
        default: return "Get Started"
        }
    }

    var body: some View {
        ZStack {
            Color(hex: "#cff1e5").ignoresSafeArea()
            BlurredBackgroundView()

            VStack(spacing: 0) {
                // Top text area - fixed positioning
                VStack {
                    Text(animatedText)
                        .multilineTextAlignment(.leading)
                        .font(Font.custom("Nunito Bold", size: 32.0))
                        .foregroundStyle(Color(hex: "#1f1f1f"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .frame(height: 120, alignment: .center) // Fixed height to prevent movement
                }

                // Middle content area - fixed height container
                ZStack {
                    // Screen 0: Welcome image
                    if currentScreen == 0 {
                        Image("welcome_image")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 400)
                            .transition(.move(edge: .leading))
                    }

                    // Screen 1: Before Pooply calendar
                    if currentScreen == 1 && showBeforeCalendar {
                        VStack(spacing: 16) {
                            HStack {
                                Text("Before Pooply")
                                    .font(.custom("Nunito Bold", size: 24))
                                    .foregroundColor(Color(hex: "#1f1f1f"))
                                Spacer()
                            }
                            .padding(.horizontal, 24)

                            DummyCalendar(isAfter: false)
                                .padding(.horizontal, 24)
                        }
                        .transition(.move(edge: .leading))
                    }

                    // Screen 2: After Pooply calendar
                    if currentScreen == 2 && showAfterCalendar {
                        VStack(spacing: 16) {
                            HStack {
                                Text("After Pooply")
                                    .font(.custom("Nunito Bold", size: 24))
                                    .foregroundColor(Color(hex: "#19b888"))
                                Spacer()
                            }
                            .padding(.horizontal, 24)

                            DummyCalendar(isAfter: true)
                                .padding(.horizontal, 24)
                        }
                        .transition(.move(edge: .leading))
                    }
                }
                .frame(height: 400) // Fixed height container to prevent layout shifts

                Spacer()
            }

            // Button pinned to bottom right
            VStack {
                Spacer()

                HStack {
                    Spacer()

                    Button(action: {
                        handleButtonPress()
                    }) {
                        HStack(spacing: 12) {
                            // Show text only on final screen
                            if currentScreen == 2 && showFixMyGutText {
                                Text("Fix my Gut")
                                    .font(.custom("Nunito Bold", size: 20))
                                    .foregroundColor(Color(hex: "3A504B"))
                                    .transition(.move(edge: .trailing).combined(with: .opacity))
                            }

                            Image(systemName: "arrow.right")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(Color(hex: "3A504B"))
                        }
                        .padding(.horizontal, currentScreen == 2 && showFixMyGutText ? 24 : 20)
                        .padding(.vertical, 20)
                        .background(Color(hex: "#19b888"))
                        .clipShape(currentScreen == 2 && showFixMyGutText ? AnyShape(Capsule()) : AnyShape(Circle()))
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showFixMyGutText)
                    }
                }
                .padding(.bottom, 40)
                .padding(.trailing, 24)
            }
        }
        .onAppear {
            startScreen0()
        }
    }

    private func handleButtonPress() {
        if currentScreen == 0 {
            // Screen 0 → 1: Swipe away welcome image, show before calendar
            withAnimation(.easeInOut(duration: 0.25)) {
                currentScreen = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                startScreen1()
            }
        } else if currentScreen == 1 {
            // Screen 1 → 2: Quick swipe away before calendar, show after calendar
            withAnimation(.easeInOut(duration: 0.25)) {
                showBeforeCalendar = false
            }
            currentScreen = 2
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                startScreen2()
            }
        } else {
            // Fix My Gut pressed - dismiss welcome view
            withAnimation(.easeInOut(duration: 0.8)) {
                isPresented = false
            }
        }
    }

    // Screen 0: "Your gut health affects everything" + image
    private func startScreen0() {
        animatedText = ""

        let fullText = "Your gut health affects\neverything."

        // Type out text
        for (index, character) in fullText.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.05) {
                animatedText += String(character)

                // Add haptic feedback for each letter (skip spaces and newlines)
                if character != " " && character != "\n" {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                }
            }
        }
    }

    // Screen 1: "See the difference" + before calendar
    private func startScreen1() {
        animatedText = ""
        showBeforeCalendar = false

        let fullText = "See the difference"

        // Type out new text
        for (index, character) in fullText.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.05) {
                animatedText += String(character)

                // Add haptic feedback for each letter (skip spaces)
                if character != " " {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                }

                if index == fullText.count - 1 {
                    // Show before calendar after typing completes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showBeforeCalendar = true
                        }
                    }
                }
            }
        }
    }

    // Screen 2: "See the difference" (static) + after calendar
    private func startScreen2() {
        // Keep the same text, don't animate it
        animatedText = "See the difference"
        showAfterCalendar = false
        showFixMyGutText = false

        // Show after calendar immediately
        withAnimation(.easeInOut(duration: 0.3)) {
            showAfterCalendar = true
        }

        // Show "Fix my Gut" text after calendar appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showFixMyGutText = true
            }
        }
    }
}

struct DummyCalendar: View {
    let isAfter: Bool

    private let daysInMonth = Array(1...30)
    private let calendar = Calendar.current

    private var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM YYYY"

        let currentDate = Date()
        let targetDate = isAfter ?
            calendar.date(byAdding: .month, value: 1, to: currentDate) ?? currentDate :
            currentDate

        return formatter.string(from: targetDate).uppercased()
    }

    private func dayColor(for day: Int) -> Color {
        if isAfter {
            // After Pooply: Mostly green with few red days
            let redDays = [3, 8, 15, 23]
            return redDays.contains(day) ? Color.red.opacity(0.7) : Color(hex: "#19b888").opacity(0.9)
        } else {
            // Before Pooply: Mostly red with few green days
            let greenDays = [5, 12, 19, 27]
            return greenDays.contains(day) ? Color(hex: "#19b888").opacity(0.9) : Color.red.opacity(0.7)
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            // Month header
            Text(monthName)
                .font(.custom("Nunito Bold", size: 14))
                .foregroundColor(.white)

            // Weekday headers
            HStack(spacing: 10) {
                ForEach(Calendar.current.shortWeekdaySymbols, id: \.self) { symbol in
                    Text(symbol.uppercased())
                        .font(.custom("Nunito Bold", size: 12))
                        .frame(maxWidth: .infinity)
                        .foregroundColor(Color(hex: "#1f1f1f"))
                }
            }

            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(spacing: 10), count: 7), spacing: 10) {
                // Empty cells for month start
                ForEach(0..<2, id: \.self) { _ in
                    Color.clear.frame(height: 44)
                }

                // Days of the month
                ForEach(daysInMonth, id: \.self) { day in
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(hex: "#e5fff7"))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(dayColor(for: day))
                            )

                        Text("\(day)")
                            .font(.custom("Nunito Black", size: 18))
                            .foregroundColor(Color(hex: "#1f1f1f"))
                    }
                    .frame(height: 44)
                }
            }
        }
        .padding()
        .background {
            ZStack {
                Color(hex: "#e5fff7").ignoresSafeArea()
                Circle().fill(Color(hex: "#19b888"))
                    .offset(x: -300, y: -300)
                    .blur(radius: 160)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 32.0, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 32.0, style: .continuous).stroke(Color(hex: "#1f1f1f").opacity(0.1), lineWidth: 1.0)
        }
        .padding(.horizontal)
    }
}

// Helper for shape morphing
struct AnyShape: Shape {
    private let _path: (CGRect) -> Path

    init<S: Shape>(_ shape: S) {
        _path = { rect in
            shape.path(in: rect)
        }
    }

    func path(in rect: CGRect) -> Path {
        return _path(rect)
    }
}

struct SurveyView: View {
    var body: some View {
        ZStack {
            Color(hex: "#cff1e5").ignoresSafeArea()
            BlurredBackgroundView()
            VStack {
                
            }
        }
    }
}

#Preview {
    WelcomeView(isPresented: .constant(true))
}
