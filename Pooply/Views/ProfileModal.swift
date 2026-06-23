//
//  ProfileModal.swift
//  Pooply
//
//  Profile page with edit and export functionality
//

import SwiftUI
import UniformTypeIdentifiers
import StoreKit

struct ProfileModal: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var subscriptionService: SubscriptionService

    @State private var showEditProfile = false
    @State private var showExportData = false
    @State private var showNotificationSettings = false
    @State private var showShareCard = false

    // Danger zone
    @State private var showLogoutConfirm = false
    @State private var showDeleteConfirm = false
    @State private var isDeletingAccount = false
    @State private var deleteErrorMessage: String?

    var body: some View {
        ZStack {
            FrostedSheetBackground()

            ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                // MARK: - Hero Zone with mascot
                ZStack(alignment: .leading) {
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        // App icon avatar — smaller, solid white border
                        Image("appLogo")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 88, height: 88)
                            .clipShape(Circle())
                            .padding(4)
                            .background(Circle().fill(Color.white))
                            .shadow(color: Color.black.opacity(0.10), radius: 6, x: 0, y: 3)

                        // Name with edit button
                        HStack(spacing: 12) {
                            Text(userViewModel.user.name)
                                .font(Theme.Fonts.hero(34))
                                .foregroundStyle(Theme.Colors.textOnMesh)

                            Button(action: {
                                Theme.Haptics.light()
                                showEditProfile = true
                            }) {
                                Text("Edit")
                                    .font(Theme.Fonts.captionBold())
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 7)
                                    .background(Capsule().fill(Theme.Colors.neutral900))
                            }
                        }

}
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Theme.Spacing.screenHorizontal)
                .padding(.top, Theme.Spacing.md)
                .padding(.bottom, Theme.Spacing.lg)

                // MARK: - Bento Stats Grid
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    // Total Logs
                    BentoStatCard(
                        value: "\(userViewModel.logHistory.count)",
                        label: "Total Logs",
                        icon: "list.bullet",
                        iconColor: Theme.Colors.textPrimary,
                        bgColor: Theme.Colors.neutral50
                    )

                    // Member Since
                    BentoStatCard(
                        value: memberSinceShort,
                        label: "Member Since",
                        icon: "calendar",
                        iconColor: Theme.Colors.mint,
                        bgColor: Theme.Colors.mint.opacity(0.1)
                    )
                }
                .padding(.horizontal, Theme.Spacing.screenHorizontal)
                .padding(.bottom, Theme.Spacing.lg)

                // MARK: - Glass Divider
                GlassDivider()
                    .padding(.horizontal, Theme.Spacing.screenHorizontal)
                    .padding(.bottom, Theme.Spacing.lg)

                // MARK: - Subscribe Card removed — app is free.

                // MARK: - Settings
                SettingsMenuCard(
                    showExportData: $showExportData,
                    showNotificationSettings: $showNotificationSettings
                )
                .padding(.horizontal, Theme.Spacing.screenHorizontal)
                .padding(.bottom, Theme.Spacing.lg)

                // MARK: - Action Buttons Row
                VStack(spacing: 12) {
                    // Share Progress button hidden for now.
                    // Button(action: {
                    //     Theme.Haptics.light()
                    //     showShareCard = true
                    // }) {
                    //     HStack(spacing: 8) {
                    //         Image(systemName: "square.and.arrow.up.fill")
                    //             .font(.system(size: 14, weight: .bold))
                    //             .foregroundStyle(Theme.Colors.textPrimary)
                    //         Text("Share Progress")
                    //             .font(Theme.Fonts.bodyBold())
                    //         Spacer()
                    //         Image(systemName: "chevron.right")
                    //             .font(.system(size: 12, weight: .bold))
                    //             .foregroundStyle(Theme.Colors.neutral300)
                    //     }
                    //     .foregroundStyle(Theme.Colors.textPrimary)
                    //     .padding(Theme.Spacing.md)
                    //     .background(Theme.Colors.neutral50)
                    //     .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous))
                    // }

                HStack(spacing: 12) {
                    ActionPillButton(
                        icon: "star.fill",
                        title: "Rate Us",
                        action: requestAppStoreReview
                    )

                    ActionPillButton(
                        icon: "bubble.left.fill",
                        title: "Contact",
                        action: openContactEmail
                    )
                }
                }
                .padding(.horizontal, Theme.Spacing.screenHorizontal)
                .padding(.bottom, Theme.Spacing.lg)

                // MARK: - Danger Zone (Log Out + Delete Account)
                ProfileDottedDivider()
                    .padding(.horizontal, Theme.Spacing.screenHorizontal)
                    .padding(.bottom, Theme.Spacing.lg)

                DangerZoneCard(
                    onLogOut: { showLogoutConfirm = true },
                    onDelete: { showDeleteConfirm = true },
                    isDeleting: isDeletingAccount
                )
                .padding(.horizontal, Theme.Spacing.screenHorizontal)
                .padding(.bottom, Theme.Spacing.lg)

                // MARK: - Footer — left-aligned slogan + version w/ dotted dividers
                ProfileDottedDivider()
                    .padding(.horizontal, Theme.Spacing.screenHorizontal)
                    .padding(.bottom, Theme.Spacing.lg)

                SloganPill()
                    .padding(.horizontal, Theme.Spacing.screenHorizontal)
                    .padding(.bottom, Theme.Spacing.lg)

                ProfileDottedDivider()
                    .padding(.horizontal, Theme.Spacing.screenHorizontal)
                    .padding(.bottom, Theme.Spacing.md)

                Text("pooply v1.0.0")
                    .font(Theme.Fonts.captionBold(13))
                    .foregroundStyle(Theme.Colors.neutral400)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Theme.Spacing.screenHorizontal)
                    .padding(.bottom, Theme.Spacing.xxl)
            }
            }
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileSheet()
                .environmentObject(userViewModel)
                .presentationBackground(.clear)
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showExportData) {
            ExportDataSheet()
                .environmentObject(userViewModel)
                .presentationBackground(.clear)
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showNotificationSettings) {
            NotificationSettingsSheet()
                .presentationBackground(.clear)
                .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $showShareCard) {
            ShareCardSheet(
                score: userViewModel.averagePoopScore(for: "WEEK"),
                goodCount: userViewModel.goodLogCount(for: "WEEK"),
                totalCount: userViewModel.totalLogCount(for: "WEEK"),
                streak: userViewModel.regularStreak,
                timeframe: "This Week"
            )
            .environmentObject(userViewModel)
        }
        // Log Out confirmation
        .alert("Log out of Pooply?", isPresented: $showLogoutConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Log Out", role: .destructive) { performLogout() }
        } message: {
            Text("You'll need to sign in again to access your gut data.")
        }
        // Delete Account confirmation (Apple-required double-confirm pattern)
        .alert("Delete your account?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { performDeleteAccount() }
        } message: {
            Text("This permanently deletes your account, all logs, and uploaded images. This cannot be undone.")
        }
        // Surface deletion errors (e.g. requires-recent-login)
        .alert("Couldn't delete account", isPresented: Binding(
            get: { deleteErrorMessage != nil },
            set: { if !$0 { deleteErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { deleteErrorMessage = nil }
        } message: {
            Text(deleteErrorMessage ?? "")
        }
    }

    private var memberSinceShort: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        if let firstLog = userViewModel.logHistory.min(by: { $0.timestamp < $1.timestamp }) {
            return formatter.string(from: firstLog.timestamp)
        }
        return formatter.string(from: Date())
    }

    // MARK: - Action handlers

    /// TODO(BEFORE LAUNCH): swap to a dedicated support address (e.g.
    /// support@pooply.app) once that mailbox exists. Personal email is fine
    /// for closed beta but reads odd in App Store reviews.
    private static let contactEmail = "grossyb12@gmail.com"

    private func requestAppStoreReview() {
        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
        else { return }
        SKStoreReviewController.requestReview(in: scene)
    }

    private func openContactEmail() {
        let subject = "Pooply support"
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? subject
        guard let url = URL(string: "mailto:\(Self.contactEmail)?subject=\(encodedSubject)") else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - Danger Zone Actions

    private func performLogout() {
        Theme.Haptics.medium()

        // 1. Sign out of Firebase Auth
        try? AuthService.shared.signOut()

        // 2. Wipe local user state so the next launch starts clean
        UserDefaultsService.shared.clearAllData()
        userViewModel.user = User(name: "Guest", age: 25, weight: 150, gender: "other")
        userViewModel.logHistory = []

        // 3. Dismiss the modal — @AppStorage("pooply_hasCompletedOnboarding")
        // in PooplyApp will see the cleared flag and re-render onboarding.
        isPresented = false
    }

    private func performDeleteAccount() {
        Theme.Haptics.medium()
        isDeletingAccount = true
        deleteErrorMessage = nil

        Task {
            do {
                // 1. Delete Firestore footprint (logs + images + user doc)
                try await FirebaseService.shared.deleteAllUserData()

                // 2. Delete the Firebase Auth account itself
                try await AuthService.shared.deleteAuthAccount()

                // 3. Wipe local state and dismiss
                await MainActor.run {
                    UserDefaultsService.shared.clearAllData()
                    userViewModel.user = User(name: "Guest", age: 25, weight: 150, gender: "other")
                    userViewModel.logHistory = []
                    isDeletingAccount = false
                    isPresented = false
                }
            } catch {
                let nsError = error as NSError
                // Surface the raw error in the Xcode console so we can diagnose
                // anything beyond the known recent-login path.
                print("[DeleteAccount] failed — domain=\(nsError.domain) code=\(nsError.code) desc=\(nsError.localizedDescription)")

                await MainActor.run {
                    isDeletingAccount = false

                    if nsError.code == 17014 /* AuthErrorCode.requiresRecentLogin */ {
                        // Firebase requires recent auth for account deletion.
                        // Sign the user out + wipe local so they're routed to
                        // onboarding and can sign in again, then retry Delete.
                        try? AuthService.shared.signOut()
                        UserDefaultsService.shared.clearAllData()
                        userViewModel.user = User(name: "Guest", age: 25, weight: 150, gender: "other")
                        userViewModel.logHistory = []
                        deleteErrorMessage = "For security, Firebase needs you to sign in again before deleting your account. We've signed you out — please sign back in and tap Delete Account once more."
                        // Dismiss the profile modal so the parent re-renders
                        // and shows the onboarding/auth flow.
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            isPresented = false
                        }
                    } else {
                        deleteErrorMessage = "\(error.localizedDescription)\n\n(Error \(nsError.code))"
                    }
                }
            }
        }
    }
}

// MARK: - Danger Zone Card

private struct DangerZoneCard: View {
    let onLogOut: () -> Void
    let onDelete: () -> Void
    let isDeleting: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Danger Zone")
                .font(Theme.Fonts.heading())
                .foregroundStyle(Theme.Colors.textPrimary)
                .padding(.bottom, Theme.Spacing.xs)

            VStack(spacing: 0) {
                SettingsMenuItem(
                    icon: "rectangle.portrait.and.arrow.right",
                    title: "Log Out",
                    action: onLogOut
                )

                Divider()
                    .overlay(Theme.Colors.neutral50)
                    .padding(.leading, 56)

                SettingsMenuItem(
                    icon: "trash.fill",
                    title: isDeleting ? "Deleting…" : "Delete Account",
                    isDestructive: true,
                    action: {
                        guard !isDeleting else { return }
                        onDelete()
                    }
                )
            }
            .glassSurface(radius: Theme.Radius.medium)
        }
    }
}

// MARK: - Action Pill Button (matches Settings-row haptic pattern)

private struct ActionPillButton: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: {
            Theme.Haptics.light()
            action()
        }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.Colors.textPrimary)
                Text(title)
                    .font(Theme.Fonts.bodyBold())
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.Colors.neutral300)
            }
            .foregroundStyle(Theme.Colors.textPrimary)
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.neutral50)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                    .stroke(Theme.Colors.neutral50, lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Slogan (left-aligned, two lines, big bold black)

struct SloganPill: View {
    var body: some View {
        VStack(alignment: .leading, spacing: -4) {
            Text("we take sh*t")
                .font(.custom("PlusJakartaSans-ExtraBold", size: 36))
                .foregroundStyle(Theme.Colors.neutral900)
            Text("seriously.")
                .font(.custom("PlusJakartaSans-ExtraBold", size: 36))
                .foregroundStyle(Theme.Colors.neutral900)
        }
        .tracking(-0.5)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Glass Divider

struct GlassDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.22))
            .frame(height: 1)
    }
}

// MARK: - Profile Dotted Divider

struct ProfileDottedDivider: View {
    var body: some View {
        GeometryReader { geo in
            let dotCount = Int(geo.size.width / 9)
            HStack(spacing: 6) {
                ForEach(0..<dotCount, id: \.self) { _ in
                    Circle()
                        .fill(Theme.Colors.neutral300)
                        .frame(width: 3, height: 3)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .frame(height: 3)
    }
}

// MARK: - Bento Stat Card

private struct BentoStatCard: View {
    let value: String
    let label: String
    let icon: String
    let iconColor: Color
    let bgColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(iconColor)
                .frame(width: 36, height: 36)
                .background(bgColor)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(Theme.Fonts.heading(28))
                    .foregroundStyle(Theme.Colors.textOnGlass)
                    .contentTransition(.numericText())

                Text(label)
                    .font(Theme.Fonts.caption())
                    .foregroundStyle(Theme.Colors.textOnGlass.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.md)
        .glassSurface(radius: Theme.Radius.medium)
    }
}

// MARK: - Header

private struct ProfileHeader: View {
    let onClose: () -> Void
    var body: some View { EmptyView() }
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
                .font(Theme.Fonts.heading())
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
                    .overlay(Theme.Colors.neutral50)
                    .padding(.leading, 56)

                SettingsMenuItem(
                    icon: "square.and.arrow.up",
                    title: "Export Data",
                    subtitle: "Download your log history",
                    action: { showExportData = true }
                )

                Divider()
                    .overlay(Theme.Colors.neutral50)
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
                    .overlay(Theme.Colors.neutral50)
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

                Divider()
                    .overlay(Theme.Colors.neutral50)
                    .padding(.leading, 56)

                SettingsMenuItem(
                    icon: "books.vertical.fill",
                    title: "Medical Sources & References",
                    subtitle: "Where our analysis comes from",
                    action: {
                        if let url = URL(string: "https://grossyb.github.io/pooply_privacy/references.html") {
                            UIApplication.shared.open(url)
                        }
                    }
                )
            }
            .glassSurface(radius: Theme.Radius.medium)
        }
    }
}

private struct SettingsMenuItem: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    var isDestructive: Bool = false
    let action: () -> Void

    private var primaryColor: Color {
        isDestructive ? Theme.Colors.blood : Theme.Colors.textPrimary
    }

    var body: some View {
        Button(action: {
            Theme.Haptics.light()
            action()
        }) {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(primaryColor)
                    .frame(width: 24, height: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Theme.Fonts.body())
                        .foregroundStyle(primaryColor)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(Theme.Fonts.caption())
                            .foregroundStyle(Theme.Colors.textTertiary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.Colors.neutral300)
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
                FrostedSheetBackground()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: Theme.Spacing.lg) {
                        // Avatar
                        Image("appLogo")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 92, height: 92)
                            .clipShape(Circle())
                            .padding(4)
                            .background(Circle().fill(Color.white))
                            .shadow(color: Color.black.opacity(0.10), radius: 6, x: 0, y: 3)
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
                    Button(action: { dismiss() }) {
                        Text("Cancel")
                            .font(Theme.Fonts.body(15))
                            .foregroundStyle(Theme.Colors.textOnGlass.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: saveProfile) {
                        Text("Save")
                            .font(Theme.Fonts.bodyBold(15))
                            .foregroundStyle(name.isEmpty ? Theme.Colors.neutral400 : Theme.Colors.neutral900)
                    }
                    .buttonStyle(.plain)
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
                FrostedSheetBackground()

                VStack(spacing: Theme.Spacing.xl) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(Theme.Colors.neutral900)
                            .frame(width: 72, height: 72)

                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .padding(.top, Theme.Spacing.xl)

                    // Title & Description
                    VStack(spacing: Theme.Spacing.sm) {
                        Text("Export Your Data")
                            .font(Theme.Fonts.heading())
                            .foregroundStyle(Theme.Colors.textOnGlass)

                        Text("Download all \(userViewModel.logHistory.count) logs as a file you can open in Excel, Numbers, or any spreadsheet app.")
                            .font(Theme.Fonts.body(14))
                            .foregroundStyle(Theme.Colors.textOnGlass.opacity(0.65))
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

                    // Export button — 3D black
                    Button(action: exportData) {
                        HStack(spacing: Theme.Spacing.sm) {
                            if isExporting {
                                ProgressView().tint(.white)
                            } else {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 16, weight: .bold))
                            }
                            Text(isExporting ? "Exporting..." : "Export \(exportFormat.rawValue)")
                                .font(Theme.Fonts.bodyBold())
                        }
                    }
                    .elevatedButtonStyle(
                        color: userViewModel.logHistory.isEmpty ? Theme.Colors.neutral400 : Theme.Colors.neutral900,
                        height: 56
                    )
                    .disabled(userViewModel.logHistory.isEmpty || isExporting)
                    .padding(.horizontal, Theme.Spacing.screenHorizontal)

                    if userViewModel.logHistory.isEmpty {
                        Text("No data to export yet")
                            .font(Theme.Fonts.caption())
                            .foregroundStyle(Theme.Colors.textOnGlass.opacity(0.5))
                    }

                    Spacer().frame(height: Theme.Spacing.lg)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(Theme.Fonts.bodyBold())
                        .foregroundStyle(Theme.Colors.neutral900)
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
            Theme.Haptics.light()
            action()
        }) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: format.icon)
                    .font(.system(size: 18))
                Text(format.rawValue)
                    .font(Theme.Fonts.bodyBold())
            }
            .foregroundStyle(isSelected ? .white : Theme.Colors.textOnGlass.opacity(0.65))
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                            .fill(Theme.Colors.neutral900)
                    } else {
                        RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                            .fill(Color.white.opacity(0.55))
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                                    .stroke(Color.white, lineWidth: 1.5)
                            )
                    }
                }
            )
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
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Theme.Colors.neutral900)
                .frame(width: 20)

            Text(text)
                .font(Theme.Fonts.body(14))
                .foregroundStyle(Theme.Colors.textOnGlass.opacity(0.75))

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
                FrostedSheetBackground()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Hero
                        VStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(Theme.Colors.neutral900)
                                    .frame(width: 76, height: 76)
                                Image(systemName: "bell.badge.fill")
                                    .font(.system(size: 30, weight: .bold))
                                    .foregroundStyle(.white)
                            }

                            VStack(spacing: 6) {
                                Text("Daily Reminder")
                                    .font(Theme.Fonts.title(26))
                                    .foregroundStyle(Theme.Colors.textOnGlass)
                                Text("A gentle nudge to log every day — your gut, on autopilot.")
                                    .font(Theme.Fonts.body(14))
                                    .foregroundStyle(Theme.Colors.textOnGlass.opacity(0.62))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 24)
                            }
                        }
                        .padding(.top, 16)

                        // Live notification preview
                        NotificationPreviewCard(time: selectedTime)
                            .padding(.horizontal, Theme.Spacing.screenHorizontal)

                        // Settings card — glass
                        VStack(spacing: 0) {
                            HStack {
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(Theme.Colors.neutral900)
                                    .frame(width: 24)

                                Text("Enable Reminder")
                                    .font(Theme.Fonts.body(15))
                                    .foregroundStyle(Theme.Colors.textOnGlass)

                                Spacer()

                                Toggle("", isOn: Binding(
                                    get: { notificationService.isEnabled },
                                    set: { newValue in
                                        if newValue { enableReminder() }
                                        else { notificationService.disableReminder() }
                                    }
                                ))
                                .tint(Theme.Colors.neutral900)
                            }
                            .padding(14)

                            if notificationService.isEnabled {
                                Divider()
                                    .overlay(Color.white.opacity(0.7))
                                    .padding(.leading, 50)

                                HStack {
                                    Image(systemName: "clock.fill")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(Theme.Colors.neutral900)
                                        .frame(width: 24)

                                    Text("Reminder Time")
                                        .font(Theme.Fonts.body(15))
                                        .foregroundStyle(Theme.Colors.textOnGlass)

                                    Spacer()

                                    DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                                        .labelsHidden()
                                        .tint(Theme.Colors.neutral900)
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
                                .padding(14)
                                .transition(.opacity)
                            }
                        }
                        .glassSurface(radius: Theme.Radius.medium)
                        .padding(.horizontal, Theme.Spacing.screenHorizontal)
                        .animation(Theme.Animation.spring, value: notificationService.isEnabled)

                        Spacer().frame(height: 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(Theme.Fonts.bodyBold())
                        .foregroundStyle(Theme.Colors.neutral900)
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

// MARK: - Notification Preview Card

private struct NotificationPreviewCard: View {
    let time: Date

    private var timeString: String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: time)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image("appLogo")
                .resizable()
                .scaledToFill()
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("Pooply")
                        .font(Theme.Fonts.captionBold(13))
                        .foregroundStyle(Theme.Colors.textOnGlass)
                    Spacer()
                    Text(timeString)
                        .font(Theme.Fonts.caption(11))
                        .foregroundStyle(Theme.Colors.textOnGlass.opacity(0.5))
                }
                Text("Time to check in 💩")
                    .font(Theme.Fonts.captionBold(13))
                    .foregroundStyle(Theme.Colors.textOnGlass)
                Text("Log today's poop to keep your streak alive.")
                    .font(Theme.Fonts.caption(12))
                    .foregroundStyle(Theme.Colors.textOnGlass.opacity(0.65))
                    .lineLimit(2)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassSurface(radius: 16)
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
