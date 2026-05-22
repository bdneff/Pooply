//
//  PooplyApp.swift
//  Pooply
//
//  Created by Brandon Grossnickle on 4/4/25.
//

import SwiftUI
import FirebaseCore
import RevenueCat
import UserNotifications
import AppTrackingTransparency

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()

        // RevenueCat
        SubscriptionService.shared.configure()

        // Notifications — show banners even when app is in foreground
        UNUserNotificationCenter.current().delegate = self

        return true
    }

    // Show notification banner when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}

@main
struct PooplyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @AppStorage("pooply_hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @StateObject private var userViewModel: UserViewModel
    @StateObject private var authService = AuthService.shared
    @StateObject private var subscriptionService = SubscriptionService.shared
    @State private var showSplash: Bool = true

    init() {
        let service = UserDefaultsService.shared
        if let savedUser = service.loadUser() {
            _userViewModel = StateObject(wrappedValue: UserViewModel(user: savedUser, withDummyData: true))
        } else {
            _userViewModel = StateObject(wrappedValue: UserViewModel(
                user: User(name: "Guest", age: 25, weight: 150, gender: "other")
            ))
        }
    }

    var body: some Scene {
        WindowGroup {
            // Splash owns the whole screen — nothing else is mounted while it's
            // visible, so no sneaky auto-focus side effects (keyboards etc.)
            // from the onboarding views below.
            if showSplash {
                SplashVideoView(isPresented: $showSplash)
                    .transition(.opacity)
            } else if !hasCompletedOnboarding {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                    .environmentObject(userViewModel)
                    .environmentObject(authService)
                    .environmentObject(subscriptionService)
                    .preferredColorScheme(.light)
                    .transition(.opacity)
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            ATTrackingManager.requestTrackingAuthorization { _ in }
                        }
                    }
            } else {
                ContentView()
                    .environmentObject(userViewModel)
                    .environmentObject(authService)
                    .environmentObject(subscriptionService)
                    .preferredColorScheme(.light)
                    .transition(.opacity)
                    .task {
                        await subscriptionService.checkSubscriptionStatus()
                        await userViewModel.loadFromFirestore()
                        subscriptionService.scheduleProNotification()
                    }
            }
        }
    }
}
