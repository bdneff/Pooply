//
//  Test.swift
//  Pooply
//
//  Created by Brandon Grossnickle on 9/19/25.
//

import SwiftUI

struct Test: View {
    let currentStreak: Int = 4
    let weeklyDays: [Bool] = [false, false, true, true, true, true, false] // Example
    
    var body: some View {
        ZStack {
            Color.pooplyBeige.ignoresSafeArea()
            VStack {
                HStack(spacing: 10) {
                    ForEach(0..<7, id: \.self) { i in
                        Circle()
                            .fill(weeklyDays[i] ? Color.green : Color.gray.opacity(0.25))
                            .frame(width: 22, height: 22)
                            .overlay(
                                Text(["M","T","W","T","F","S","S"][i].prefix(1))
                                    .font(.caption2.bold())
                                    .foregroundColor(.white)
                            )
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal)
                VStack {
                    GutZoneGaugeView(score: 88.0, color: .green, label: "GUT ZONE")
                HStack {
                        CircularGaugeView(score: 88, color: .blue.opacity(0.7),
                                          label: "HYDRATION", imageName: "water")
                        .frame(maxWidth: .infinity)
                        CircularGaugeView(score: 67, color: .orange,
                                          label: "FIBER", imageName: "wheat")
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding()
                JournalEntryView()
                    .padding()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16.0, style: .continuous))
                StreakCardView()
                Spacer()
            }
        }
    }
}

#Preview {
    Test()
}

struct FlyoverView: View {
    @State private var progress: CGFloat = 0.60   // 0→1 along BASE arc

    var body: some View {
        ZStack {
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height

                // —— Responsive geometry (all % based) ——
                let stroke: CGFloat = min(w, h) * 0.16
                let radius: CGFloat = min(w, h)
                let center = CGPoint(x: w/2, y: h)

                let baseStart = Angle.degrees(0)
                let baseEnd   = Angle.degrees(360)
                let hiStart   = Angle.degrees(270)
                let hiEnd     = Angle.degrees(210)

                ZStack {
                    // Base arc
                    Arc(center: center, radius: radius, start: baseStart, end: baseEnd)
                        .stroke(LinearGradient(colors: [.pooplyDarkBeige.opacity(0.16)], startPoint: .leading, endPoint: .trailing), style: StrokeStyle(lineWidth: stroke, lineCap: .round))

                    // Highlight arc
                    Arc(center: center, radius: radius, start: hiStart, end: hiEnd)
                        .stroke(Color.green.gradient,
                                style: StrokeStyle(lineWidth: stroke, lineCap: .round))
                }
            }
            VStack(spacing: 4) {
                Text("88")
                    .font(.system(size: 64, weight: .bold))
                Text("GUT ZONE")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 90, height: 120)
    }

    private func point(on c: CGPoint, radius r: CGFloat, angle a: Angle) -> CGPoint {
        let t = CGFloat(a.radians)
        return CGPoint(x: c.x + cos(t) * r, y: c.y + sin(t) * r)
    }
}

// MARK: Shapes

struct Arc: Shape {
    var center: CGPoint
    var radius: CGFloat
    var start: Angle
    var end: Angle
    func path(in _: CGRect) -> Path {
        var p = Path()
        p.addArc(center: center, radius: radius, startAngle: start, endAngle: end, clockwise: false)
        return p
    }
}

/// Curved beam: top edge follows the HIGHLIGHT'S inner arc (radius - stroke/2),
/// then tapers to an apex. Optional rounded sides via quad curves.
struct BeamCurved: Shape {
    var center: CGPoint
    var radius: CGFloat      // arc CENTERLINE radius
    var stroke: CGFloat
    var start: Angle         // highlight start
    var end: Angle           // highlight end
    var apexDrop: CGFloat    // how far below center the apex is (pts)
    var sideCurve: CGFloat = 0.0 // 0 = straight sides, >0 = rounded sides

    func path(in _: CGRect) -> Path {
        let rInner = radius - stroke / 2

        let a1 = CGFloat(start.radians)
        let a2 = CGFloat(end.radians)
        let p1 = CGPoint(x: center.x + cos(a1) * rInner,
                         y: center.y + sin(a1) * rInner)
        let p2 = CGPoint(x: center.x + cos(a2) * rInner,
                         y: center.y + sin(a2) * rInner)

        // Apex directly below the arc center
        let apex = CGPoint(x: center.x, y: center.y + apexDrop)

        var p = Path()
        // 1) Top edge = inner arc (this makes it “take up the arc space”)
        p.addArc(center: center, radius: rInner,
                 startAngle: start, endAngle: end, clockwise: false)

        // 2) From right end → apex
        if sideCurve > 0 {
            // rounded side using a control point halfway down
            let c2 = CGPoint(x: (p2.x + apex.x)/2 + sideCurve*(p2.x - center.x)/rInner,
                             y: (p2.y + apex.y)/2 + sideCurve*(p2.y - center.y)/rInner)
            p.addQuadCurve(to: apex, control: c2)
        } else {
            p.addLine(to: apex)
        }

        // 3) From apex → left end
        if sideCurve > 0 {
            let c1 = CGPoint(x: (p1.x + apex.x)/2 + sideCurve*(p1.x - center.x)/rInner,
                             y: (p1.y + apex.y)/2 + sideCurve*(p1.y - center.y)/rInner)
            p.addQuadCurve(to: p1, control: c1)
        } else {
            p.addLine(to: p1)
        }

        p.closeSubpath()
        return p
    }
}

struct GutZoneGaugeView: View {
    var score: Double
    var color: Color
    var label: String

    var body: some View {
        VStack {
            ZStack {
                // Background circle
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 8)

                // Progress circle
                Circle()
                    .trim(from: 0, to: score / 100)
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 4) {
                    Text("\(Int(score))")
                        .font(.system(size: 48, weight: .bold))
                    Text(label.uppercased())
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 160, height: 160)
        }
    }
}

struct CircularGaugeView: View {
    var score: Double
    var color: Color
    var label: String
    var imageName: String

    var body: some View {
        VStack {
            ZStack {
                // Background circle
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 4)

                // Progress circle
                Circle()
                    .trim(from: 0, to: score / 100)
                    .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 8) {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }
            }
            .frame(width: 64, height: 64)
            VStack(spacing: 4) {
                Text("\(Int(score))%")
                    .font(.system(size: 20, weight: .bold))
                Text(label.uppercased())
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct StreakCardView: View {
    let currentStreak: Int = 4
    let weeklyDays: [Bool] = [false, false, true, true, true, true, false] // Example
    let goal: Int = 7
    let progress: Double = 0.78 // 78% toward weekly goal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                VStack(spacing: 6) {
                    Image("fire")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 48, height: 48)
                        .foregroundColor(.green)
                    Text("\(currentStreak) days")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.black)
                    Text("GREEN STREAK")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .frame(width: 120, height: 110)
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "calendar")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .bold()
                        Text("This Week")
                            .font(.headline)
                    }
                    
                    // Weekly dots
                    HStack(spacing: 10) {
                        ForEach(0..<7, id: \.self) { i in
                            Circle()
                                .fill(weeklyDays[i] ? Color.green : Color.gray.opacity(0.25))
                                .frame(width: 22, height: 22)
                                .overlay(
                                    Text(["M","T","W","T","F","S","S"][i].prefix(1))
                                        .font(.caption2.bold())
                                        .foregroundColor(.white)
                                )
                        }
                    }
                }
            }
        }
        .padding(20)
        .frame(height: 160)
        .padding(.horizontal)
    }
}

struct JournalEntryView: View {
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "book.pages")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .bold()
                Text("How is your gut feeling right now?")
                    .font(.headline)
            }
            Text("Start typing...")
                .padding(.leading)
                .foregroundStyle(.gray)
        }
    }
}





