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

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
class ManageSubscriptionsViewModel: ObservableObject {

    var isLoaded: Bool {
        if case .notLoaded = state {
            return false
        }
        return true
    }

    @Published
    var subscriptionInformation: SubscriptionInformation?
    @Published
    var refundRequestStatus: String?
    @Published
    var configuration: CustomerCenterConfigData?
    @Published
    var showRestoreAlert: Bool = false
    @Published var state: State {
        didSet {
            if case let .error(stateError) = state {
                self.error = stateError
            }
        }
    }

    private var error: Error?

    enum State {

        case notLoaded
        case success
        case error(Error)

    }

    init() {
        state = .notLoaded
    }

    init(configuration: CustomerCenterConfigData) {
        state = .notLoaded
        self.configuration = configuration
    }

    init(configuration: CustomerCenterConfigData, subscriptionInformation: SubscriptionInformation) {
        self.configuration = configuration
        self.subscriptionInformation = subscriptionInformation
        state = .success
    }

    func loadSubscriptionInformation() async {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            guard let currentEntitlementDict = customerInfo.entitlements.active.first,
                  let subscribedProductID = customerInfo.activeSubscriptions.first,
                  let subscribedProduct = await Purchases.shared.products([subscribedProductID]).first else {
                Logger.warning(Strings.could_not_find_subscription_information)
                self.state = .error(CustomerCenterError.couldNotFindSubscriptionInformation)
                return
            }
            let currentEntitlement = currentEntitlementDict.value

            // swiftlint:disable:next todo
            // TODO: support non-consumables
            self.subscriptionInformation = SubscriptionInformation(
                title: subscribedProduct.localizedTitle,
                durationTitle: subscribedProduct.subscriptionPeriod?.durationTitle ?? "",
                price: subscribedProduct.localizedPriceString,
                nextRenewalString: currentEntitlement.expirationDate.map { "\($0)" } ?? nil,
                willRenew: currentEntitlement.willRenew,
                productIdentifier: subscribedProductID,
                active: currentEntitlement.isActive
            )
        } catch {
            self.state = .error(error)
        }
    }

    func loadCustomerCenterConfig() async {
        do {
            self.configuration = CustomerCenterConfigTestData.customerCenterData
        } catch {
            self.state = .error(error)
        }
    }

    #if os(iOS) || targetEnvironment(macCatalyst)
    func handleAction(for path: CustomerCenterConfigData.HelpPath) {
        switch path.type {
        case .missingPurchase:
            self.showRestoreAlert = true
        case .refundRequest:
            Task {
                guard let subscriptionInformation = self.subscriptionInformation else { return }
                let status = try await Purchases.shared.beginRefundRequest(
                    forProduct: subscriptionInformation.productIdentifier
                )
                switch status {
                case .error:
                    self.refundRequestStatus = "Error when requesting refund, try again"
                case .success:
                    self.refundRequestStatus = "Refund granted successfully!"
                case .userCancelled:
                    self.refundRequestStatus = "Refund canceled"
                }
            }
        case .changePlans:
            Task {
                try await Purchases.shared.showManageSubscriptions()
            }
        case .cancel:
            Task {
                try await Purchases.shared.showManageSubscriptions()
            }
        default:
            break
        }
    }
    #endif

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
