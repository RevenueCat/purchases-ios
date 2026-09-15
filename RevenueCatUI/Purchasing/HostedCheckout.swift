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
    enum Start: Equatable {

        /// Present this checkout to the customer.
        case present(HostedCheckoutSession)

        /// The customer cannot be taken to a checkout of ours, so the purchase goes through StoreKit, as it
        /// would on an SDK that does not know this purchase method.
        case buyThroughStoreKit

        /// Nothing to present, and nothing to offer instead: the customer declined Apple's notice, the device
        /// does not authorize payments, another checkout is already starting, or the checkout could not be
        /// created. Each of those is reported where it happens.
        case nothing

        init(_ result: HostedCheckoutStartResult) {
            switch result {
            case let .started(session):
                self = .present(session)
            case .externalPurchaseUnavailable:
                self = .buyThroughStoreKit
            case .declinedByCustomer, .paymentsNotAuthorized, .alreadyStarting, .failed:
                self = .nothing
            }
        }

    }

    /// Runs Apple's flow and creates the checkout session, with the paywall marked as busy throughout so the
    /// button the customer tapped cannot start a second one.
    static func start(for package: Package, purchaseHandler: PurchaseHandler) async -> Start {
        guard Purchases.isConfigured else {
            return .buyThroughStoreKit
        }

        // Carried so that the purchase the customer makes on the page is attributed to the paywall that sent
        // them there.
        let paywallEvent = purchaseHandler.createPurchaseInitiatedEvent(package: package)

        let result = await purchaseHandler.withExternalPurchasePreparation {
            await Purchases.shared.startHostedCheckout(package: package, paywallEvent: paywallEvent)
        }

        return Start(result)
    }

}

#endif
