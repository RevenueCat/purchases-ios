//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ExternalPurchaseLink.swift
//
//  Created by Antonio Pallares on 8/9/26.

import Foundation
@_spi(Internal) import RevenueCat

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
enum ExternalPurchaseLink {

    /// What the paywall does with the tap on a web purchase link.
    enum Action: Equatable {

        /// Open this link.
        case open(URL)

        /// Tell the customer the purchase is not available to them, which is why nothing opens.
        case tellCustomerThePurchaseIsUnavailable

        /// Open nothing, and offer nothing instead.
        case nothing

        init(_ result: ExternalPurchaseLinkResult, url: URL) {
            switch result {
            case let .proceed(externalPurchaseTokenID):
                self = .open(externalPurchaseTokenID.map(url.appendingExternalPurchaseTokenID) ?? url)
            case .notEligible:
                self = .tellCustomerThePurchaseIsUnavailable
            case .stopped:
                self = .nothing
            }
        }

    }

    /// What to do with a web purchase link, once whatever Apple requires before the customer leaves the app
    /// has been done.
    ///
    /// The paywall is marked as busy while Apple's flow runs, so the button the customer tapped cannot start a
    /// second one. Links that open straight away are not marked, to save a blink of a disabled button.
    static func action(for url: URL,
                       method: PaywallComponent.ButtonComponent.URLMethod,
                       purchaseHandler: PurchaseHandler) async -> Action {
        guard self.applies(to: method, purchaseHandler: purchaseHandler) else {
            return .open(url)
        }

        return Action(await purchaseHandler.prepareExternalPurchaseLink(), url: url)
    }

    /// Whether opening a link with this method goes through Apple's external purchase flow.
    ///
    /// Only external browser links take part: leaving the app is what Apple's programme covers.
    private static func applies(to method: PaywallComponent.ButtonComponent.URLMethod,
                                purchaseHandler: PurchaseHandler) -> Bool {
        return method == .externalBrowser && purchaseHandler.useExternalPurchaseCustomLinks
    }

}

extension URL {

    /// The name the checkout page reads the external purchase token id from.
    static let externalPurchaseTokenIDParameter = "rc_external_purchase_token_id"

    func appendingExternalPurchaseTokenID(_ tokenID: String) -> URL {
        return self.upserting([.init(name: Self.externalPurchaseTokenIDParameter, value: tokenID)])
    }

}

#endif
