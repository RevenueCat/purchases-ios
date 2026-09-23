//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  HostedCheckout.swift
//
//  Created by Antonio Pallares on 11/9/26.

import Foundation
@_spi(Internal) import RevenueCat

#if os(iOS) && canImport(WebKit)

/// Starts the checkout a purchase button configured for the in-app sheet asks for.
@available(iOS 15.0, *)
enum HostedCheckout {

    /// What the paywall does with the tap that asked for a checkout.
    enum Action: Equatable {

        /// Present this checkout to the customer.
        case present(HostedCheckoutSession)

        /// Tell the customer they already own what they tried to buy, which is why no checkout opens.
        case tellCustomerTheyAlreadyOwnIt

        /// Nothing to present, and nothing to offer instead.
        case nothing

        init(_ result: HostedCheckoutStartResult) {
            switch result {
            case let .started(session):
                self = .present(session)
            case .alreadyPurchased:
                self = .tellCustomerTheyAlreadyOwnIt
            case .declinedByCustomer, .paymentsNotAuthorized, .notAllowedInStorefront, .alreadyStarting, .failed:
                self = .nothing
            }
        }

    }

    /// Runs Apple's flow and creates the checkout session, once the app's purchase interceptor lets it.
    static func start(for package: Package,
                      purchaseHandler: PurchaseHandler,
                      purchaseInitiatedAction: PurchaseInitiatedAction?) async -> Action {
        guard await purchaseHandler.shouldProceed(withPurchaseOf: package,
                                                  interceptor: purchaseInitiatedAction) else {
            return .nothing
        }

        return Action(await purchaseHandler.startHostedCheckout(package: package))
    }

}

#endif
