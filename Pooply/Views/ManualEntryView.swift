//
//  ManualEntryView.swift
//  Pooply
//
//  Created by Brandon Grossnickle on 10/24/25.
//

import SwiftUI

struct ManualEntryView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var userViewModel: UserViewModel

    @State private var selectedType: Log.PoopType = .smoothSausage
    @State private var selectedColor: Log.PoopColor = .mediumBrown
    @State private var selectedSize: Log.PoopSize = .medium
    @State private var containsBlood = false
    @State private var useCurrentTime = true
    @State private var selectedDate = Date()

    private let allTypes: [Log.PoopType] = Log.PoopType.allCases

    private let allColors: [Log.PoopColor] = [
        .lightBrown, .mediumBrown, .darkBrown, .green, .yellow, .black, .red
    ]

    private let allSizes: [Log.PoopSize] = [
        .small, .medium, .large
    ]

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
                    Text("Manual")
                        .font(.headline)
                        .foregroundColor(Color(hex: "#1f1f1f"))
                    Spacer()
                    Button(action: { saveLog() }) {
                        Text("Save")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(hex: "#1f1f1f"))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color(hex: "#e5fff7"))
                            .clipShape(Capsule())
                    }
                }
                .padding()

                ScrollView {
                    VStack(spacing: 32) {

                        // Date Selection
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Date")
                                .font(.custom("Nunito Bold", size: 18))
                                .foregroundColor(Color(hex: "#1f1f1f"))

                            HStack(spacing: 16) {
                                Button(action: { useCurrentTime = true }) {
                                    Text("Now")
                                        .font(.custom("Nunito Regular", size: 16))
                                        .foregroundColor(useCurrentTime ? .black : .white)
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 12)
                                        .background(useCurrentTime ? Color(hex: "#19b888") : Color.white.opacity(0.1))
                                        .clipShape(Capsule())
                                }

                                Button(action: { useCurrentTime = false }) {
                                    Text("Select Date")
                                        .font(.custom("Nunito Regular", size: 16))
                                        .foregroundColor(!useCurrentTime ? .black : .white)
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 12)
                                        .background(!useCurrentTime ? Color(hex: "#19b888") : Color.white.opacity(0.1))
                                        .clipShape(Capsule())
                                }
                            }

                            if !useCurrentTime {
                                DatePicker("Select Date", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                                    .datePickerStyle(.wheel)
                                    .colorScheme(.dark)
                                    .labelsHidden()
                                    .padding()
                                    .background(Color(hex: "#e5fff7"))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }

                        // Type Selection
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Type")
                                .font(.custom("Nunito Bold", size: 18))
                                .foregroundColor(Color(hex: "#1f1f1f"))

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                                ForEach(allTypes, id: \.self) { type in
                                    Button(action: { selectedType = type }) {
                                        VStack(spacing: 8) {
                                            Image(type.rawValue)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 60, height: 60)
                                                .padding(12)
                                                .background(selectedType == type ? Color(hex: "#19b888").opacity(0.2) : Color.white.opacity(0.1))
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(selectedType == type ? Color(hex: "#19b888") : Color.clear, lineWidth: 2)
                                                )
                                        }
                                    }
                                }
                            }
                        }

                        // Color Selection
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Color")
                                .font(.custom("Nunito Bold", size: 18))
                                .foregroundColor(Color(hex: "#1f1f1f"))

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                                ForEach(allColors, id: \.self) { color in
                                    Button(action: { selectedColor = color }) {
                                        Circle()
                                            .fill(colorForPoopColor(color))
                                            .frame(width: 50, height: 50)
                                            .overlay(
                                                Circle()
                                                    .stroke(selectedColor == color ? Color.white : Color.clear, lineWidth: 3)
                                            )
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                            )
                                    }
                                }
                            }
                        }

                        // Size Selection
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Size")
                                .font(.custom("Nunito Bold", size: 18))
                                .foregroundColor(Color(hex: "#1f1f1f"))

                            HStack(spacing: 16) {
                                ForEach(allSizes, id: \.self) { size in
                                    Button(action: { selectedSize = size }) {
                                        Text(size.rawValue.capitalized)
                                            .font(.custom("Nunito Regular", size: 16))
                                            .foregroundColor(selectedSize == size ? .black : .white)
                                            .padding(.horizontal, 24)
                                            .padding(.vertical, 12)
                                            .background(selectedSize == size ? Color(hex: "#19b888") : Color.white.opacity(0.1))
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }

                        // Blood Toggle
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Contains Blood")
                                .font(.custom("Nunito Bold", size: 18))
                                .foregroundColor(Color(hex: "#1f1f1f"))

                            HStack {
                                Text("Contains Blood")
                                    .font(.custom("Nunito Regular", size: 16))
                                    .foregroundColor(Color(hex: "#1f1f1f"))
                                Spacer()
                                Toggle("", isOn: $containsBlood)
                                    .labelsHidden()
                                    .toggleStyle(SwitchToggleStyle(tint: Color(hex: "#19b888")))
                            }
                            .padding()
                            .background(Color(hex: "#e5fff7"))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding()
                }
            }
        }
    }

    private func colorForPoopColor(_ poopColor: Log.PoopColor) -> Color {
        switch poopColor {
        case .lightBrown: return Color(hex: "#D2B48C")
        case .mediumBrown: return Color(hex: "#8B4513")
        case .darkBrown: return Color(hex: "#654321")
        case .green: return Color(hex: "#228B22")
        case .yellow: return Color(hex: "#FFD700")
        case .black: return Color(hex: "#2F2F2F")
        case .red: return Color(hex: "#B22222")
        }
    }

    private func saveLog() {
        let timestamp = useCurrentTime ? Date() : selectedDate

        let newLog = userViewModel.createManualLog(
            type: selectedType,
            color: selectedColor,
            size: selectedSize,
            containsBlood: containsBlood,
            timestamp: timestamp
        )

        userViewModel.addLog(newLog)
        isPresented = false
    }
}


#Preview {
    ManualEntryView(isPresented: .constant(true))
}
