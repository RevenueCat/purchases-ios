//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WinBackOffer.swift
//
//  Created by Will Taylor on 10/29/24.

import Foundation
import StoreKit

/// Represents a ``StoreProductDiscount``
///
/// #### Related Symbols
/// - ``Purchases/promotionalOffer(forProductDiscount:product:)``
/// - ``Purchases/getPromotionalOffer(forProductDiscount:product:completion:)``
/// - ``StoreProduct/eligiblePromotionalOffers()``
/// - ``Purchases/eligiblePromotionalOffers(forProduct:)``
/// - ``Purchases/purchase(package:promotionalOffer:)``
/// - ``Purchases/purchase(package:promotionalOffer:completion:)``
/// - ``Purchases/purchase(product:promotionalOffer:)``
/// - ``Purchases/purchase(product:promotionalOffer:completion:)``
@available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
@objc(RCWinBackOffer)
internal final class WinBackOffer: NSObject {

    /// The ``StoreProductDiscount`` in this offer.
    @objc internal let discount: StoreProductDiscount

    init(discount: StoreProductDiscount) {
        self.discount = discount
    }

}

@available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
extension WinBackOffer: Sendable {}
