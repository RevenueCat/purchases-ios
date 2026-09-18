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

        /// Nothing to present, and nothing to offer instead.
        case nothing

        init(_ result: HostedCheckoutStartResult) {
            switch result {
            case let .started(session):
                self = .present(session)
            case .declinedByCustomer, .paymentsNotAuthorized, .alreadyStarting, .failed:
                self = .nothing
            }
        }

    }

    /// Runs Apple's flow and creates the checkout session.
    static func start(for package: Package, purchaseHandler: PurchaseHandler) async -> Start {
        return Start(await purchaseHandler.startHostedCheckout(package: package))
    }

}

#endif
