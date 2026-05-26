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
    // Splash video disabled for beta — app launches straight to Welcome/Get
    // Started (or ContentView if already onboarded). Flip this back to `true`
    // and uncomment the splash branch below to re-enable.
    @State private var showSplash: Bool = false

    init() {
        let service = UserDefaultsService.shared
        if let savedUser = service.loadUser() {
            _userViewModel = StateObject(wrappedValue: UserViewModel(user: savedUser, withDummyData: false))
        } else {
            _userViewModel = StateObject(wrappedValue: UserViewModel(
                user: User(name: "Guest", age: 25, weight: 150, gender: "other"),
                withDummyData: false
            ))
        }
    }

    var body: some Scene {
        WindowGroup {
            // Splash disabled for beta — see `showSplash` declaration above.
            // if showSplash {
            //     SplashVideoView(isPresented: $showSplash)
            //         .transition(.opacity)
            // } else
            if !hasCompletedOnboarding {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                    .environmentObject(userViewModel)
                    .environmentObject(authService)
                    .environmentObject(subscriptionService)
                    .preferredColorScheme(.light)
                    .transition(.opacity)
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
