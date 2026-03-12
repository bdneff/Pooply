//
//  ProfileModal.swift
//  Pooply
//
//  Profile page with edit and export functionality
//

import SwiftUI
import UniformTypeIdentifiers

struct ProfileModal: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var subscriptionService: SubscriptionService

    @State private var showEditProfile = false
    @State private var showExportData = false
    @State private var showNotificationSettings = false
    @State private var showPaywall = false

    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: - Header
                ProfileHeader(onClose: { isPresented = false })

                // MARK: - Content
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: Theme.Spacing.lg) {

                        // MARK: - Pro Upsell (if not subscribed)
                        if !subscriptionService.isSubscribed {
                            PooplyProCard(onUpgrade: { showPaywall = true })
                        }

                        // MARK: - Profile Card
                        ProfileInfoCard(showEditProfile: $showEditProfile)

                        // MARK: - Stats Row
                        ProfileStatsRow()

                        // MARK: - Settings Menu
                        SettingsMenuCard(
                            showExportData: $showExportData,
                            showNotificationSettings: $showNotificationSettings
                        )

                        // Bottom spacing
                        Spacer().frame(height: Theme.Spacing.xxl)
                    }
                    .padding(.horizontal, Theme.Spacing.screenHorizontal)
                    .padding(.top, Theme.Spacing.md)
                }
            }
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileSheet()
                .environmentObject(userViewModel)
        }
        .sheet(isPresented: $showExportData) {
            ExportDataSheet()
                .environmentObject(userViewModel)
        }
        .sheet(isPresented: $showNotificationSettings) {
            NotificationSettingsSheet()
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView()
                .environmentObject(subscriptionService)
        }
    }
}

// MARK: - Header

private struct ProfileHeader: View {
    let onClose: () -> Void

    var body: some View {
        HStack {
            CloseButton(action: onClose)

            Spacer()

            Text("Profile")
                .font(Theme.Fonts.subheading())
                .foregroundStyle(Theme.Colors.textPrimary)

            Spacer()

            // Invisible balance spacer
            Color.clear
                .frame(width: 32, height: 32)
        }
        .padding(.horizontal, Theme.Spacing.screenHorizontal)
        .padding(.vertical, Theme.Spacing.md)
    }
}

// MARK: - Profile Info Card

private struct ProfileInfoCard: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @Binding var showEditProfile: Bool

    private var memberSinceText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        if let firstLog = userViewModel.logHistory.min(by: { $0.timestamp < $1.timestamp }) {
            return "Member since \(formatter.string(from: firstLog.timestamp))"
        }
        return "Member since \(formatter.string(from: Date()))"
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Avatar with edit button
            ZStack(alignment: .bottomTrailing) {
                ZStack {
                    Circle()
                        .fill(Theme.Colors.primary.opacity(0.15))
                        .frame(width: 88, height: 88)

                    Text(userViewModel.user.name.prefix(1).uppercased())
                        .font(Theme.Fonts.hero(36))
                        .foregroundStyle(Theme.Colors.primary)
                }

                // Edit button
                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    showEditProfile = true
                }) {
                    Image(systemName: "pencil")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.Colors.textOnPrimary)
                        .frame(width: 28, height: 28)
                        .background(Theme.Colors.primary)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Theme.Colors.cardBackground, lineWidth: 2)
                        )
                }
                .offset(x: 4, y: 4)
            }

            // Name & Info
            VStack(spacing: 4) {
                Text(userViewModel.user.name)
                    .font(Theme.Fonts.heading())
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text(memberSinceText)
                    .font(Theme.Fonts.caption())
                    .foregroundStyle(Theme.Colors.textTertiary)
            }

            // Profile details row
            HStack(spacing: Theme.Spacing.lg) {
                ProfileDetailChip(label: "\(userViewModel.user.age) yrs")
                ProfileDetailChip(label: "\(Int(userViewModel.user.weight)) lbs")
                ProfileDetailChip(label: userViewModel.user.gender.capitalized)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.lg)
        .padding(.horizontal, Theme.Spacing.cardPadding)
        .background(Theme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.large, style: .continuous))
        .cardShadow()
    }
}

private struct ProfileDetailChip: View {
    let label: String

    var body: some View {
        Text(label)
            .font(Theme.Fonts.caption())
            .foregroundStyle(Theme.Colors.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Theme.Colors.backgroundSecondary)
            .clipShape(Capsule())
    }
}

// MARK: - Profile Stats Row

private struct ProfileStatsRow: View {
    @EnvironmentObject var userViewModel: UserViewModel

    private var totalLogs: Int {
        userViewModel.logHistory.count
    }

    private var regularStreak: Int {
        userViewModel.regularStreak
    }

    private var avgPoopScore: Int {
        let logs = userViewModel.logHistory
        guard !logs.isEmpty else { return 0 }
        let totalScore = logs.reduce(0) { $0 + userViewModel.calculatePoopScore(for: $1) }
        return totalScore / logs.count
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ProfileStatItem(value: "\(totalLogs)", label: "Total Logs", icon: "list.bullet")
            ProfileStatItem(value: "\(regularStreak)", label: "Day Streak", icon: "flame.fill")
            ProfileStatItem(value: "\(avgPoopScore)", label: "Avg Score", icon: "chart.line.uptrend.xyaxis")
        }
    }
}

private struct ProfileStatItem: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(Theme.Colors.primary)

            Text(value)
                .font(Theme.Fonts.heading())
                .foregroundStyle(Theme.Colors.textPrimary)
                .contentTransition(.numericText())

            Text(label.uppercased())
                .font(Theme.Fonts.label(10))
                .foregroundStyle(Theme.Colors.textTertiary)
                .tracking(0.3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.md)
        .background(Theme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous))
        .cardShadow()
    }
}

// MARK: - Settings Menu Card

private struct SettingsMenuCard: View {
    @Binding var showExportData: Bool
    @Binding var showNotificationSettings: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Settings")
                .font(Theme.Fonts.subheading())
                .foregroundStyle(Theme.Colors.textPrimary)
                .padding(.bottom, Theme.Spacing.xs)

            VStack(spacing: 0) {
                SettingsMenuItem(
                    icon: "bell.fill",
                    title: "Notifications",
                    subtitle: "Reminders & alerts",
                    action: { showNotificationSettings = true }
                )

                Divider()
                    .padding(.leading, 56)

                SettingsMenuItem(
                    icon: "square.and.arrow.up",
                    title: "Export Data",
                    subtitle: "Download your log history",
                    action: { showExportData = true }
                )

                Divider()
                    .padding(.leading, 56)

                SettingsMenuItem(
                    icon: "doc.text.fill",
                    title: "Terms of Service",
                    action: {
                        if let url = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/") {
                            UIApplication.shared.open(url)
                        }
                    }
                )

                Divider()
                    .padding(.leading, 56)

                SettingsMenuItem(
                    icon: "hand.raised.fill",
                    title: "Privacy Policy",
                    action: {
                        if let url = URL(string: "https://grossyb.github.io/pooply_privacy/") {
                            UIApplication.shared.open(url)
                        }
                    }
                )
            }
            .background(Theme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous))
            .cardShadow()

            // App Version
            Text("pooply v1.0.0")
                .font(Theme.Fonts.micro())
                .foregroundStyle(Theme.Colors.textTertiary)
                .frame(maxWidth: .infinity)
                .padding(.top, Theme.Spacing.lg)
        }
    }
}

private struct SettingsMenuItem: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: {
            let impactLight = UIImpactFeedbackGenerator(style: .light)
            impactLight.impactOccurred()
            action()
        }) {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(Theme.Colors.primary)
                    .frame(width: 24, height: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Theme.Fonts.body())
                        .foregroundStyle(Theme.Colors.textPrimary)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(Theme.Fonts.caption())
                            .foregroundStyle(Theme.Colors.textTertiary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
            .padding(Theme.Spacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Edit Profile Sheet

struct EditProfileSheet: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var age: Int = 25
    @State private var weight: Double = 150
    @State private var gender: String = "female"

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: Theme.Spacing.lg) {
                        // Avatar
                        ZStack {
                            Circle()
                                .fill(Theme.Colors.primary.opacity(0.15))
                                .frame(width: 100, height: 100)

                            Text(name.prefix(1).uppercased())
                                .font(Theme.Fonts.hero(42))
                                .foregroundStyle(Theme.Colors.primary)
                        }
                        .padding(.top, Theme.Spacing.lg)

                        // Name field
                        ProfileInputCard(title: "Name", icon: "person.fill") {
                            TextField("Enter your name", text: $name)
                                .font(Theme.Fonts.body())
                                .foregroundStyle(Theme.Colors.textPrimary)
                        }

                        // Age picker
                        ProfileInputCard(title: "Age", icon: "calendar") {
                            Picker("Age", selection: $age) {
                                ForEach(13..<100, id: \.self) { age in
                                    Text("\(age) years").tag(age)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 120)
                        }

                        // Weight picker
                        ProfileInputCard(title: "Weight", icon: "scalemass.fill") {
                            Picker("Weight", selection: $weight) {
                                ForEach(Array(stride(from: 80.0, through: 400.0, by: 5.0)), id: \.self) { weight in
                                    Text("\(Int(weight)) lbs").tag(weight)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 120)
                        }

                        // Gender selector
                        ProfileInputCard(title: "Gender", icon: "figure.stand") {
                            HStack(spacing: Theme.Spacing.sm) {
                                GenderOptionButton(title: "Female", isSelected: gender == "female") {
                                    gender = "female"
                                }
                                GenderOptionButton(title: "Male", isSelected: gender == "male") {
                                    gender = "male"
                                }
                                GenderOptionButton(title: "Other", isSelected: gender == "other") {
                                    gender = "other"
                                }
                            }
                        }

                        Spacer().frame(height: Theme.Spacing.xxl)
                    }
                    .padding(.horizontal, Theme.Spacing.screenHorizontal)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(Theme.Colors.textSecondary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveProfile()
                    }
                    .font(Theme.Fonts.bodyBold())
                    .foregroundStyle(name.isEmpty ? Theme.Colors.neutralLight : Theme.Colors.primary)
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                // Load current values
                name = userViewModel.user.name
                age = userViewModel.user.age
                weight = userViewModel.user.weight
                gender = userViewModel.user.gender
            }
        }
    }

    private func saveProfile() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        // Update user
        let updatedUser = User(
            name: name,
            age: age,
            weight: weight,
            gender: gender
        )

        userViewModel.user = updatedUser

        // Save to UserDefaults
        UserDefaultsService.shared.saveUser(updatedUser)

        // Save to Firestore
        Task { try? await FirebaseService.shared.saveUserProfile(updatedUser, questionnaireAnswers: [:]) }

        dismiss()
    }
}

// MARK: - Export Data Sheet

struct ExportDataSheet: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var exportFormat: ExportFormat = .csv
    @State private var isExporting = false

    enum ExportFormat: String, CaseIterable {
        case csv = "CSV"
        case json = "JSON"

        var icon: String {
            switch self {
            case .csv: return "tablecells"
            case .json: return "curlybraces"
            }
        }

        var fileExtension: String {
            rawValue.lowercased()
        }

        var mimeType: UTType {
            switch self {
            case .csv: return .commaSeparatedText
            case .json: return .json
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()

                VStack(spacing: Theme.Spacing.xl) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(Theme.Colors.primary.opacity(0.12))
                            .frame(width: 80, height: 80)

                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 32))
                            .foregroundStyle(Theme.Colors.primary)
                    }
                    .padding(.top, Theme.Spacing.xl)

                    // Title & Description
                    VStack(spacing: Theme.Spacing.sm) {
                        Text("Export Your Data")
                            .font(Theme.Fonts.heading())
                            .foregroundStyle(Theme.Colors.textPrimary)

                        Text("Download all \(userViewModel.logHistory.count) logs as a file you can open in Excel, Numbers, or any spreadsheet app.")
                            .font(Theme.Fonts.body())
                            .foregroundStyle(Theme.Colors.textTertiary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Theme.Spacing.lg)
                    }

                    // Format selector
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("FORMAT")
                            .font(Theme.Fonts.label())
                            .foregroundStyle(Theme.Colors.textTertiary)
                            .padding(.horizontal, Theme.Spacing.screenHorizontal)

                        HStack(spacing: Theme.Spacing.sm) {
                            ForEach(ExportFormat.allCases, id: \.self) { format in
                                ExportFormatButton(
                                    format: format,
                                    isSelected: exportFormat == format,
                                    action: { exportFormat = format }
                                )
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.screenHorizontal)
                    }

                    // Data preview
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("INCLUDES")
                            .font(Theme.Fonts.label())
                            .foregroundStyle(Theme.Colors.textTertiary)

                        VStack(spacing: Theme.Spacing.xs) {
                            ExportIncludesRow(icon: "calendar", text: "Date & Time")
                            ExportIncludesRow(icon: "circle.lefthalf.filled", text: "Bristol Type & Category")
                            ExportIncludesRow(icon: "paintpalette", text: "Color & Size")
                            ExportIncludesRow(icon: "drop.fill", text: "Hydration & Fiber %")
                            ExportIncludesRow(icon: "heart.fill", text: "Blood Presence")
                            ExportIncludesRow(icon: "chart.bar.fill", text: "Poop Score")
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.screenHorizontal)

                    Spacer()

                    // Export button
                    Button(action: exportData) {
                        HStack(spacing: Theme.Spacing.sm) {
                            if isExporting {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            Text(isExporting ? "Exporting..." : "Export \(exportFormat.rawValue)")
                                .font(Theme.Fonts.bodyBold())
                        }
                        .foregroundStyle(Theme.Colors.textOnPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(userViewModel.logHistory.isEmpty ? Theme.Colors.neutralLight : Theme.Colors.primary)
                        .clipShape(Capsule())
                    }
                    .disabled(userViewModel.logHistory.isEmpty || isExporting)
                    .padding(.horizontal, Theme.Spacing.screenHorizontal)

                    if userViewModel.logHistory.isEmpty {
                        Text("No data to export yet")
                            .font(Theme.Fonts.caption())
                            .foregroundStyle(Theme.Colors.textTertiary)
                    }

                    Spacer().frame(height: Theme.Spacing.lg)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(Theme.Fonts.bodyBold())
                    .foregroundStyle(Theme.Colors.primary)
                }
            }
        }
    }

    private func exportData() {
        isExporting = true

        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        DispatchQueue.global(qos: .userInitiated).async {
            let fileContent: String
            let fileName: String

            switch exportFormat {
            case .csv:
                fileContent = generateCSV()
                fileName = "pooply_logs_\(dateStamp()).csv"
            case .json:
                fileContent = generateJSON()
                fileName = "pooply_logs_\(dateStamp()).json"
            }

            DispatchQueue.main.async {
                isExporting = false
                shareFile(content: fileContent, fileName: fileName)
            }
        }
    }

    private func dateStamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private func generateCSV() -> String {
        var csv = "Date,Time,Bristol Type,Category,Color,Size,Hydration %,Fiber %,Blood %,Poop Score\n"

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"

        for log in userViewModel.logHistory.sorted(by: { $0.timestamp < $1.timestamp }) {
            let date = dateFormatter.string(from: log.timestamp)
            let time = timeFormatter.string(from: log.timestamp)
            let type = log.type.rawValue
            let category = log.poopScore.rawValue
            let color = log.color.rawValue
            let size = log.size.rawValue
            let hydration = Int((log.hydrationPercentage ?? 0) * 100)
            let fiber = Int((log.fiberPercentage ?? 0) * 100)
            let blood = Int(log.bloodPercentage * 100)
            let score = userViewModel.calculatePoopScore(for: log)

            csv += "\(date),\(time),\(type),\(category),\(color),\(size),\(hydration),\(fiber),\(blood),\(score)\n"
        }

        return csv
    }

    private func generateJSON() -> String {
        let dateFormatter = ISO8601DateFormatter()

        let logs = userViewModel.logHistory.sorted(by: { $0.timestamp < $1.timestamp }).map { log -> [String: Any] in
            return [
                "timestamp": dateFormatter.string(from: log.timestamp),
                "bristolType": log.type.rawValue,
                "category": log.poopScore.rawValue,
                "color": log.color.rawValue,
                "size": log.size.rawValue,
                "hydrationPercentage": log.hydrationPercentage ?? 0,
                "fiberPercentage": log.fiberPercentage ?? 0,
                "bloodPercentage": log.bloodPercentage,
                "poopScore": userViewModel.calculatePoopScore(for: log)
            ]
        }

        let export: [String: Any] = [
            "exportDate": dateFormatter.string(from: Date()),
            "totalLogs": logs.count,
            "logs": logs
        ]

        if let jsonData = try? JSONSerialization.data(withJSONObject: export, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }

        return "{}"
    }

    private func shareFile(content: String, fileName: String) {
        guard let data = content.data(using: .utf8) else { return }

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try data.write(to: tempURL)

            let activityVC = UIActivityViewController(
                activityItems: [tempURL],
                applicationActivities: nil
            )

            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                var topVC = rootVC
                while let presented = topVC.presentedViewController {
                    topVC = presented
                }
                topVC.present(activityVC, animated: true)
            }
        } catch {
            // Export failed silently — file write error
        }
    }
}

private struct ExportFormatButton: View {
    let format: ExportDataSheet.ExportFormat
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            action()
        }) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: format.icon)
                    .font(.system(size: 18))
                Text(format.rawValue)
                    .font(Theme.Fonts.bodyBold())
            }
            .foregroundStyle(isSelected ? Theme.Colors.textOnPrimary : Theme.Colors.textSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(isSelected ? Theme.Colors.primary : Theme.Colors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct ExportIncludesRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(Theme.Colors.primary)
                .frame(width: 20)

            Text(text)
                .font(Theme.Fonts.body())
                .foregroundStyle(Theme.Colors.textSecondary)

            Spacer()

            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Theme.Colors.good)
        }
        .padding(.vertical, Theme.Spacing.xs)
    }
}

// MARK: - Notification Settings Sheet

struct NotificationSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var notificationService = NotificationService.shared

    @State private var selectedTime = Date()
    @State private var showPermissionAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()

                VStack(spacing: Theme.Spacing.xl) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(Theme.Colors.primary.opacity(0.12))
                            .frame(width: 80, height: 80)

                        Image(systemName: "bell.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(Theme.Colors.primary)
                    }
                    .padding(.top, Theme.Spacing.xl)

                    // Title
                    VStack(spacing: Theme.Spacing.sm) {
                        Text("Daily Reminder")
                            .font(Theme.Fonts.heading())
                            .foregroundStyle(Theme.Colors.textPrimary)

                        Text("Get a gentle nudge to log every day and stay consistent with your gut health tracking.")
                            .font(Theme.Fonts.body())
                            .foregroundStyle(Theme.Colors.textTertiary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Theme.Spacing.lg)
                    }

                    // Toggle
                    VStack(spacing: 0) {
                        HStack {
                            Image(systemName: "bell.badge.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(Theme.Colors.primary)
                                .frame(width: 24)

                            Text("Enable Reminder")
                                .font(Theme.Fonts.body())
                                .foregroundStyle(Theme.Colors.textPrimary)

                            Spacer()

                            Toggle("", isOn: Binding(
                                get: { notificationService.isEnabled },
                                set: { newValue in
                                    if newValue {
                                        enableReminder()
                                    } else {
                                        notificationService.disableReminder()
                                    }
                                }
                            ))
                            .tint(Theme.Colors.primary)
                        }
                        .padding(Theme.Spacing.md)

                        if notificationService.isEnabled {
                            Divider()
                                .padding(.leading, 56)

                            HStack {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(Theme.Colors.primary)
                                    .frame(width: 24)

                                Text("Reminder Time")
                                    .font(Theme.Fonts.body())
                                    .foregroundStyle(Theme.Colors.textPrimary)

                                Spacer()

                                DatePicker(
                                    "",
                                    selection: $selectedTime,
                                    displayedComponents: .hourAndMinute
                                )
                                .labelsHidden()
                                .onChange(of: selectedTime) { _, newValue in
                                    let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                                    Task {
                                        await notificationService.updateReminderTime(
                                            hour: components.hour ?? 9,
                                            minute: components.minute ?? 0
                                        )
                                    }
                                }
                            }
                            .padding(Theme.Spacing.md)
                        }
                    }
                    .background(Theme.Colors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous))
                    .cardShadow()
                    .padding(.horizontal, Theme.Spacing.screenHorizontal)

                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(Theme.Fonts.bodyBold())
                        .foregroundStyle(Theme.Colors.primary)
                }
            }
            .onAppear {
                // Sync time picker with saved values
                var components = DateComponents()
                components.hour = notificationService.reminderHour
                components.minute = notificationService.reminderMinute
                if let date = Calendar.current.date(from: components) {
                    selectedTime = date
                }
            }
            .alert("Notifications Disabled", isPresented: $showPermissionAlert) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Please enable notifications in Settings to receive daily reminders.")
            }
        }
    }

    private func enableReminder() {
        Task {
            let components = Calendar.current.dateComponents([.hour, .minute], from: selectedTime)
            await notificationService.enableDailyReminder(
                hour: components.hour ?? 9,
                minute: components.minute ?? 0
            )
            // If still not enabled after requesting, show settings alert
            if !notificationService.isEnabled {
                showPermissionAlert = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ProfileModal(isPresented: .constant(true))
        .environmentObject(
            UserViewModel(
                user: User(name: "Jessica", age: 25, weight: 160, gender: "female"),
                withDummyData: true
            )
        )
        .environmentObject(SubscriptionService.shared)
}
