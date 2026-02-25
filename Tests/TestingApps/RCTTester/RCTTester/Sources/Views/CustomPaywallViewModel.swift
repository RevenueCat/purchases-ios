//
//  CustomPaywallViewModel.swift
//  RCTTester
//
//  Mirrors the customer's RevenueCatPaywallViewModel pattern to reproduce
//  the Posthog analytics inflation issue (paywall callbacks firing multiple times).
//

import SwiftUI
import RevenueCat

@available(iOS 17.0, *)
@Observable
@MainActor
final class CustomPaywallViewModel {

    @ObservationIgnored private let offeringIdentifier: String
    @ObservationIgnored private var currentSubscriptionProductId: String?
    @ObservationIgnored private let onDismiss: () -> Void

    enum State {
        case loading
        case loaded(Offering)
        case error(String)
    }

    var state: State = .loading
    var isPurchasing: Bool = false

    init(
        offeringIdentifier: String,
        onDismiss: @escaping () -> Void
    ) {
        self.offeringIdentifier = offeringIdentifier
        self.onDismiss = onDismiss
    }

    func onFirstAppearTask() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadOffering() }
            group.addTask { await self.fetchCurrentSubscription() }
        }
    }

    func onRetry() async {
        await loadOffering()
    }

    private func loadOffering() async {
        state = .loading

        do {
            let offerings = try await Purchases.shared.offerings()
            let currentOffering = offerings.offering(identifier: offeringIdentifier) ?? offerings.current

            guard let currentOffering else {
                state = .error("No offering found")
                return
            }

            state = .loaded(currentOffering)
            print("[PaywallTracker][Analytics] paywallShown — offering: \(currentOffering.identifier)")
        } catch {
            print("❌ Failed to load RevenueCat paywall: \(error.localizedDescription)")
            state = .error(error.localizedDescription)
        }
    }

    private func fetchCurrentSubscription() async {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            currentSubscriptionProductId = customerInfo.activeSubscriptions.first
        } catch {
            // Ignore — best-effort
        }
    }

    func onClose() {
        guard !isPurchasing else { return }
        print("[PaywallTracker][Analytics] paywallClosed — offering: \(offeringId ?? "nil")")
        onDismiss()
    }

    func onPurchaseInitiated() {
        isPurchasing = true
        print("[PaywallTracker][Analytics] paywallCtaTapped — offering: \(offeringId ?? "nil")")
    }

    private var offeringId: String? {
        switch state {
        case let .loaded(offering):
            offering.identifier
        default:
            nil
        }
    }

    func onPurchaseCancelled() {
        isPurchasing = false
    }

    func onPurchaseError(_ error: Error) {
        isPurchasing = false
        print("❌ Purchase error: \(error.localizedDescription)")
    }

    func onPurchaseCompleted(customerInfo: CustomerInfo) async {
        let productId = customerInfo.activeSubscriptions.first ?? ""

        print("[PaywallTracker][Analytics] paywallPurchased — offering: \(offeringId ?? "nil"), product: \(productId)")

        await monitorSubscriptionChange()
        isPurchasing = false
        onDismiss()
    }

    func onRestoreCompleted(customerInfo: CustomerInfo) async {
        guard !customerInfo.activeSubscriptions.isEmpty else { return }

        isPurchasing = true
        await monitorSubscriptionChange()
        isPurchasing = false

        onDismiss()
    }

    /// Mirrors the customer's polling pattern: checks every 2 seconds for up to 30 seconds
    /// to detect when the backend has processed the purchase.
    private func monitorSubscriptionChange() async {
        for attempt in 0 ..< 15 {
            try? await Task.sleep(nanoseconds: 2_000_000_000)

            do {
                let customerInfo = try await Purchases.shared.customerInfo()
                let newProductId = customerInfo.activeSubscriptions.first
                if newProductId != currentSubscriptionProductId {
                    print("✅ Subscription change detected after \(attempt + 1) attempt(s)")
                    return
                }
            } catch {
                // continue polling
            }
        }
        print("⏱️ monitorSubscriptionChange timed out after 30s")
    }
}
