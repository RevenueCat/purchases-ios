//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ManageSubscriptionsViewModel.swift
//
//
//  Created by Cesar de la Vega on 27/5/24.
//

import Foundation
import RevenueCat

#if !os(macOS) && !os(tvOS) && !os(watchOS) && !os(visionOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@MainActor
class ManageSubscriptionsViewModel: ObservableObject {

    @Published
    var subscriptionInformation: SubscriptionInformation?
    @Published
    var refundRequestStatusMessage: String?
    @Published
    var configuration: CustomerCenterConfigData?
    @Published
    var showRestoreAlert: Bool = false
    @Published
    var state: CustomerCenterViewState {
        didSet {
            if case let .error(stateError) = state {
                self.error = stateError
            }
        }
    }

    var isLoaded: Bool {
        return state != .notLoaded
    }

    private var purchasesProvider: ManageSubscriptionsPurchaseType

    private var error: Error?

    convenience init() {
        self.init(purchasesProvider: ManageSubscriptionPurchases())
    }

    // @PublicForExternalTesting
    init(purchasesProvider: ManageSubscriptionsPurchaseType) {
        self.state = .notLoaded
        self.purchasesProvider = purchasesProvider
    }

    // @PublicForExternalTesting
    init(configuration: CustomerCenterConfigData,
         subscriptionInformation: SubscriptionInformation) {
        self.configuration = configuration
        self.subscriptionInformation = subscriptionInformation
        self.purchasesProvider = ManageSubscriptionPurchases()
        state = .success
    }

    func loadScreen() async {
        do {
            try await loadSubscriptionInformation()
            await loadCustomerCenterConfig()
            self.state = .success
        } catch {
            self.state = .error(error)
        }
    }

    func loadSubscriptionInformation() async throws {
        let customerInfo = try await purchasesProvider.customerInfo()
        guard let currentEntitlementDict = customerInfo.entitlements.active.first,
              let subscribedProductID = customerInfo.activeSubscriptions.first,
              let subscribedProduct = await purchasesProvider.products([subscribedProductID]).first else {
            Logger.warning(Strings.could_not_find_subscription_information)
            throw CustomerCenterError.couldNotFindSubscriptionInformation
        }
        let currentEntitlement = currentEntitlementDict.value

        // swiftlint:disable:next todo
        // TODO: support non-consumables
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        self.subscriptionInformation = SubscriptionInformation(
            title: subscribedProduct.localizedTitle,
            durationTitle: subscribedProduct.subscriptionPeriod?.durationTitle ?? "",
            price: subscribedProduct.localizedPriceString,
            nextRenewalString: currentEntitlement.expirationDate.map { dateFormatter.string(from: $0) } ?? nil,
            willRenew: currentEntitlement.willRenew,
            productIdentifier: subscribedProductID,
            active: currentEntitlement.isActive
        )
    }

    func loadCustomerCenterConfig() async {
        self.configuration = CustomerCenterConfigTestData.customerCenterData
    }

    #if os(iOS) || targetEnvironment(macCatalyst)
    func handleAction(for path: CustomerCenterConfigData.HelpPath) {
        switch path.type {
        case .missingPurchase:
            self.showRestoreAlert = true
        case .refundRequest:
            Task {
                guard let subscriptionInformation = self.subscriptionInformation else { return }
                let productId = subscriptionInformation.productIdentifier
                let status = try await purchasesProvider.beginRefundRequest(forProduct: productId)
                switch status {
                case .error:
                    self.refundRequestStatusMessage = "Error when requesting refund, try again"
                case .success:
                    self.refundRequestStatusMessage = "Refund granted successfully!"
                case .userCancelled:
                    self.refundRequestStatusMessage = "Refund canceled"
                }
            }
        case .changePlans, .cancel:
            Task {
                try await purchasesProvider.showManageSubscriptions()
            }
        default:
            break
        }
    }
    #endif

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private final class ManageSubscriptionPurchases: ManageSubscriptionsPurchaseType {

    func beginRefundRequest(forProduct productID: String) async throws -> RevenueCat.RefundRequestStatus {
        try await Purchases.shared.beginRefundRequest(forProduct: productID)
    }

    func showManageSubscriptions() async throws {
        try await Purchases.shared.showManageSubscriptions()
    }

    func customerInfo() async throws -> RevenueCat.CustomerInfo {
        return try await Purchases.shared.customerInfo()
    }

    func products(_ productIdentifiers: [String]) async -> [StoreProduct] {
        return await Purchases.shared.products(productIdentifiers)
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private extension SubscriptionPeriod {

    var durationTitle: String {
        switch self.unit {
        case .day: return "day"
        case .week: return "week"
        case .month: return "month"
        case .year: return "year"
        default: return "Unknown"
        }
    }

}

#endif
