// Created by Monika on 2026-10-14.

import Foundation
@_spi(Internal) import RevenueCat
@_spi(Internal) import RevenueCatUI
import SwiftUI

/// Exercises the mobile app's SPI entry point, including the sheet it owns, without test-only SDK hooks.
struct CustomerCenterPreviewFixture: View {
    static let name = "customer_center_preview"
    @StateObject private var provider = CustomerCenterPreviewFixtureProvider()

    var body: some View {
        VStack {
            Text(Purchases.isConfigured ? "SDK configured" : "SDK unconfigured")
            Text(provider.events.joined(separator: " | "))
                .accessibilityIdentifier("preview.events")
            CustomerCenterView(uiPreviewPurchaseProvider: provider, navigationOptions: .default)
        }
    }
}

@MainActor
private final class CustomerCenterPreviewFixtureProvider: ObservableObject, CustomerCenterPreviewProvider {
    nonisolated let appUserID = "preview customer"
    nonisolated let isSandbox = true
    nonisolated let isConfigured = true
    nonisolated let storeFrontCountryCode: String? = "US"
    @Published private(set) var events: [String] = []
    private let offering = CustomerCenterPreviewFixtureData.offering()
    private let info = CustomerInfo(entitlements: .init(), requestDate: Date(), firstSeen: Date(),
                                    originalAppUserId: "preview customer")

    func customerInfo() async throws -> CustomerInfo { info }
    func customerInfo(fetchPolicy: CacheFetchPolicy) async throws -> CustomerInfo { info }
    func customerInfoUpdates() async -> AsyncStream<CustomerInfo> { AsyncStream { $0.finish() } }
    func products(_ ids: [String]) async -> [StoreProduct] { offering.availablePackages.map(\.storeProduct) }
    func offerings() async throws -> Offerings { .preview(offerings: [offering], currentOfferingID: offering.identifier) }
    func syncPurchases() async throws -> CustomerInfo { info }
    func restorePurchases() async throws -> CustomerInfo {
        events.append("restore")
        return info
    }
    func purchase(package: Package) async throws -> PurchaseResultData {
        events.append("purchase")
        switch ProcessInfo.processInfo.environment["PREVIEW_ACTION_OUTCOME"] {
        case "cancel": throw ErrorCode.purchaseCancelledError
        case "failure": throw NSError(domain: "Preview", code: 1,
                                       userInfo: [NSLocalizedDescriptionKey: "Preview purchase failed"])
        default: return (nil, info, false)
        }
    }
    func purchase(product: StoreProduct, promotionalOffer: PromotionalOffer?) async throws -> PurchaseResultData {
        events.append("purchase")
        return (nil, info, false)
    }
    func promotionalOffer(forProductDiscount discount: StoreProductDiscount,
                          product: StoreProduct) async throws -> PromotionalOffer { throw ErrorCode.configurationError }
    func createTicket(customerEmail: String, ticketDescription: String) async throws -> Bool { true }
    func beginRefundRequest(forProduct productID: String) async throws -> RefundRequestStatus { .success }
    nonisolated func track(customerCenterEvent: any CustomerCenterEventType) {}
    nonisolated func invalidateVirtualCurrenciesCache() {}
    func virtualCurrencies() async throws -> VirtualCurrencies { .init(virtualCurrencies: [:]) }
    func manageSubscriptionsSheetViewModifier(isPresented: Binding<Bool>,
                                             subscriptionGroupID: String?) -> ManageSubscriptionSheetModifier {
        .init(isPresented: .constant(false), subscriptionGroupID: nil)
    }
    func handlePreviewAction(_ action: CustomerCenterPreviewAction) async throws {
        if case let .openURL(url) = action {
            let outcome = ProcessInfo.processInfo.environment["PREVIEW_ACTION_OUTCOME"]
            if outcome == "delayed" {
                try await Task.sleep(nanoseconds: 3_000_000_000)
            } else if outcome == "failure" {
                throw NSError(domain: "Preview", code: 1,
                              userInfo: [NSLocalizedDescriptionKey: "Preview checkout failed"])
            }
            events.append(url.absoluteString)
        }
    }
    func loadCustomerCenter() async throws -> CustomerCenterConfigData {
        .init(
            screens: [.noActive: .init(type: .noActive, title: "Preview Customer Center", subtitle: "No purchases",
                                      paths: [], offering: .init(type: .current, offeringId: nil,
                                                                 buttonText: "Open preview"))],
            appearance: .init(accentColor: .init(), textColor: .init(), backgroundColor: .init(),
                              buttonTextColor: .init(), buttonBackgroundColor: .init()),
            localization: .init(locale: "en_US", localizedStrings: ["contact_support": "Contact support"]),
            support: .init(email: "support@example.invalid", shouldWarnCustomerToUpdate: false,
                           displayPurchaseHistoryLink: false, displayUserDetailsSection: false,
                           displayVirtualCurrencies: false),
            changePlans: [], lastPublishedAppVersion: nil, productId: nil
        )
    }
}
