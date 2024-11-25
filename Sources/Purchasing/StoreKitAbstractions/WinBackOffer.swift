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

/// Represents an Apple win-back offer.
@objc(RCWinBackOffer)
public final class WinBackOffer: NSObject, Sendable {

    /// The ``StoreProductDiscount`` in this offer.
    @objc public let discount: StoreProductDiscount

    init(discount: StoreProductDiscountType) {
        self.discount = StoreProductDiscount.from(discount: discount)
    }
}
