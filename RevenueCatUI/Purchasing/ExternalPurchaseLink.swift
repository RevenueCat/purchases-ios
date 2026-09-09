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

    /// The link to open for a web purchase, once whatever Apple requires before the customer leaves the app
    /// has been done. `nil` when nothing should open, because the customer declined Apple's notice.
    ///
    /// The paywall is marked as busy while Apple's flow runs, so the button the customer tapped cannot start a
    /// second one. Links that open straight away are not marked, to save a blink of a disabled button.
    static func urlToOpen(_ url: URL,
                          method: PaywallComponent.ButtonComponent.URLMethod,
                          purchaseHandler: PurchaseHandler) async -> URL? {
        guard self.applies(to: method) else {
            return url
        }

        return await purchaseHandler.withExternalPurchasePreparation {
            await self.urlToOpen(url)
        }
    }

    /// Whether opening a link with this method goes through Apple's external purchase flow.
    ///
    /// Only external browser links take part: leaving the app is what Apple's programme covers.
    private static func applies(to method: PaywallComponent.ButtonComponent.URLMethod) -> Bool {
        guard method == .externalBrowser, Purchases.isConfigured else {
            return false
        }

        return Purchases.shared.preparesExternalPurchaseLinks
    }

    private static func urlToOpen(_ url: URL) async -> URL? {
        switch await Purchases.shared.prepareExternalPurchaseLink() {
        case let .proceed(externalPurchaseTokenID):
            guard let externalPurchaseTokenID else {
                return url
            }

            return url.appendingExternalPurchaseTokenID(externalPurchaseTokenID)
        case .stopped:
            return nil
        }
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
