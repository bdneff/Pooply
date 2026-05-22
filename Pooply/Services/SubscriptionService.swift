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

    // App is currently FREE — everyone is treated as subscribed.
    // RevenueCat / paywall gating intentionally short-circuited.
    @Published var isSubscribed: Bool = true
    @Published var offerings: Offerings?
    @Published var isLoading: Bool = false

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

    // App is free — no analysis cap.
    var freeAnalysesRemaining: Int {
        Int.max
    }

    var canUseAIAnalysis: Bool {
        true
    }

    func useAnalysis() {
        // No-op while the app is free.
    }

    // MARK: - Configuration

    func configure() {
        // App is free for beta — RevenueCat is fully dormant.
        // Everything that gated features is short-circuited; isSubscribed is
        // always true and no purchase flow can be reached from the UI.
        // Purchases.logLevel = .debug
        // Purchases.configure(withAPIKey: "appl_MnpaNEJmMAixIEbWNKJDlqxfsJq")
        // Purchases.shared.delegate = self
        self.isSubscribed = true
        self.isLoading = false
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
        // App is free — short-circuit any RevenueCat / StoreKit check.
        self.isSubscribed = true
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
        // No upsell while app is free.
    }
}

// MARK: - PurchasesDelegate

extension SubscriptionService: PurchasesDelegate {
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        // App is free — ignore RevenueCat updates and keep isSubscribed true.
    }
}
