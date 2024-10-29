//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DeepLink.swift
//
//  Created by Antonio Rico Diez on 2024-10-17.

import Foundation

@objc public extension Purchases {

    /// Class representing a RevenueCat deep link that can be processed by the SDK.
    class DeepLink: NSObject {

        private override init() {}

        // swiftlint:disable nesting

        /// Class representing a web redemption deep link that can be redeemed by the SDK.
        /// - Seealso: ``Purchases/redeemWebPurchase(_:)``
        @objc public final class WebPurchaseRedemption: DeepLink {

            internal let redemptionToken: String

            internal init(redemptionToken: String) {
                self.redemptionToken = redemptionToken
            }

        }

        // swiftlint:enable nesting

    }

}
