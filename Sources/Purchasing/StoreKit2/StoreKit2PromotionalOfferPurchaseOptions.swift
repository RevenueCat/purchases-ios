//
//  StoreKit2PromotionalOfferPurchaseOptions.swift
//  RevenueCat
//
//  Created by Will Taylor on 12/4/25.
//  Copyright © 2025 RevenueCat, Inc. All rights reserved.
//

import Foundation

/**
 * ``StoreKit2PromotionalOfferPurchaseOptions`` can be used to apply promotional offers to StoreKit 2 purchases.
 */
@objc(StoreKit2PromotionalOfferPurchaseOptions)
public final class StoreKit2PromotionalOfferPurchaseOptions: NSObject, Sendable {
    /// The id property of the subscription offer to apply.
    public let offerID: String

    /// The JWS signature used to validate a promotional offer.
    public let compactJWS: String

    /**
     * Creates a new ``StoreKit2PromotionalOfferPurchaseOptions`` instance.
     * - Parameters:
     *   - offerID: The id property of the subscription offer to apply.
     *   - compactJWS: The JWS signature used to validate a promotional offer.
     */
    public init(
        offerID: String,
        compactJWS: String
    ) {
        self.offerID = offerID
        self.compactJWS = compactJWS
    }
}
