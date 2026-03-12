//
//  SubscriptionService.swift
//  Pooply
//
//  RevenueCat subscription management with freemium model
//

import Foundation
import StoreKit
import RevenueCat

class SubscriptionService: NSObject, ObservableObject {
    static let shared = SubscriptionService()

    @Published var isSubscribed: Bool = false
    @Published var offerings: Offerings?
    @Published var isLoading: Bool = true

    // StoreKit 2 fallback products
    @Published var storeProducts: [StoreKit.Product] = []

    private override init() { super.init() }

    private let inviteAccessKey = "pooply_inviteCodeAccess"
    private let freeAnalysesKey = "pooply_freeAnalysesUsed"
    private let productIDs = ["pooply_monthly", "pooply_annual"]

    static let maxFreeAnalyses = 3

    // MARK: - Free Analysis Tracking

    var freeAnalysesUsed: Int {
        get { UserDefaults.standard.integer(forKey: freeAnalysesKey) }
        set { UserDefaults.standard.set(newValue, forKey: freeAnalysesKey) }
    }

    var freeAnalysesRemaining: Int {
        max(0, Self.maxFreeAnalyses - freeAnalysesUsed)
    }

    var canUseAIAnalysis: Bool {
        isSubscribed || freeAnalysesRemaining > 0
    }

    func useAnalysis() {
        if !isSubscribed {
            freeAnalysesUsed += 1
        }
    }

    // MARK: - Configuration

    func configure() {
        if UserDefaults.standard.bool(forKey: inviteAccessKey) {
            self.isSubscribed = true
        }

        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: "appl_MnpaNEJmMAixIEbWNKJDlqxfsJq")
        Purchases.shared.delegate = self

        Task {
            await checkSubscriptionStatus()
            await fetchOfferings()
        }
    }

    // MARK: - Invite Code Access

    @MainActor
    func grantInviteAccess() {
        isSubscribed = true
        UserDefaults.standard.set(true, forKey: inviteAccessKey)
    }

    // MARK: - Subscription Status

    @MainActor
    func checkSubscriptionStatus() async {
        let hasInviteAccess = UserDefaults.standard.bool(forKey: inviteAccessKey)

        // Check RevenueCat
        var rcActive = false
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            rcActive = customerInfo.entitlements["pro"]?.isActive == true
        } catch { }

        // Check StoreKit 2 directly (covers local sandbox purchases)
        var skActive = false
        for await result in Transaction.currentEntitlements {
            if case .verified(_) = result {
                skActive = true
                break
            }
        }

        self.isSubscribed = rcActive || skActive || hasInviteAccess
        self.isLoading = false
    }

    // MARK: - Offerings

    @MainActor
    func fetchOfferings() async {
        do {
            let offerings = try await Purchases.shared.offerings()
            self.offerings = offerings
            if offerings.current == nil {
                await loadStoreKitProducts()
            }
        } catch {
            await loadStoreKitProducts()
        }
    }

    // MARK: - StoreKit 2 Fallback

    @MainActor
    private func loadStoreKitProducts() async {
        do {
            let products = try await StoreKit.Product.products(for: productIDs)
            self.storeProducts = products.sorted { $0.price < $1.price }
        } catch { }
    }

    @MainActor
    private func checkStoreKitEntitlements() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(_) = result {
                self.isSubscribed = true
                return
            }
        }
    }

    // MARK: - Purchase (RevenueCat)

    @MainActor
    func purchase(_ package: Package) async throws -> Bool {
        let result = try await Purchases.shared.purchase(package: package)
        let isActive = result.customerInfo.entitlements["pro"]?.isActive == true
        self.isSubscribed = isActive
        return isActive
    }

    // MARK: - Purchase (StoreKit 2 fallback)

    @MainActor
    func purchaseStoreProduct(_ product: StoreKit.Product) async throws -> Bool {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            if case .verified(let transaction) = verification {
                await transaction.finish()
                self.isSubscribed = true
                return true
            }
            return false
        case .userCancelled:
            return false
        case .pending:
            return false
        @unknown default:
            return false
        }
    }

    // MARK: - Restore

    @MainActor
    func restorePurchases() async throws -> Bool {
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            let isActive = customerInfo.entitlements["pro"]?.isActive == true
            if isActive {
                self.isSubscribed = true
                return true
            }
        } catch { }

        await checkStoreKitEntitlements()
        return self.isSubscribed
    }

    // MARK: - Package Helpers (RevenueCat)

    var monthlyPackage: Package? {
        offerings?.current?.package(identifier: "$rc_monthly") ?? offerings?.current?.monthly
    }

    var annualPackage: Package? {
        offerings?.current?.package(identifier: "$rc_annual") ?? offerings?.current?.annual
    }

    // MARK: - StoreKit 2 Helpers

    var monthlyProduct: StoreKit.Product? {
        storeProducts.first { $0.id == "pooply_monthly" }
    }

    var annualProduct: StoreKit.Product? {
        storeProducts.first { $0.id == "pooply_annual" }
    }

    var hasProducts: Bool {
        monthlyPackage != nil || monthlyProduct != nil
    }

    var monthlyPriceString: String {
        monthlyPackage?.localizedPriceString ?? monthlyProduct?.displayPrice ?? "$6.99"
    }

    var annualPriceString: String {
        annualPackage?.localizedPriceString ?? annualProduct?.displayPrice ?? "$29.99"
    }

    // MARK: - Pro Notification

    func scheduleProNotification() {
        guard !isSubscribed else { return }

        let content = UNMutableNotificationContent()
        content.title = "Unlock AI Poop Analysis"
        content.body = "Upgrade to Pooply Pro for instant AI scoring, smart insights, and personalized recommendations."
        content.sound = .default

        // Schedule for 3 days after install
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 259200, repeats: false)
        let request = UNNotificationRequest(identifier: "pooply_pro_promo", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - PurchasesDelegate

extension SubscriptionService: PurchasesDelegate {
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        DispatchQueue.main.async {
            let hasActiveSubscription = customerInfo.entitlements["pro"]?.isActive == true
            let hasInviteAccess = UserDefaults.standard.bool(forKey: self.inviteAccessKey)
            self.isSubscribed = hasActiveSubscription || hasInviteAccess
        }
    }
}
