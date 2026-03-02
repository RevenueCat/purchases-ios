//
//  StoreKit2PromotionalOfferPurchaseOptions.swift
//  RevenueCat
//
//  Created by Will Taylor on 12/4/25.
//  Copyright © 2025 RevenueCat, Inc. All rights reserved.
//

import Foundation

// StoreKit2PromotionalOfferPurchaseOptions is only public when custom entitlement computation is enabled.
// However, certain internal classes (like PurchasesOrchestrator) need to access the type even when
// custom entitlement computation is disabled. Therefore, we use `internal` access control in that case
// to allow access to the type within the module.
//
// We should keep the two different type definitions and implementations in sync, and remove the internal copy
// if we ever make StoreKit2PromotionalOfferPurchaseOptions public unconditionally.

#if ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION

/**
 * ``StoreKit2PromotionalOfferPurchaseOptions`` can be used to apply promotional offers to StoreKit 2 purchases.
 */
@objc(StoreKit2PromotionalOfferPurchaseOptions)
public final class StoreKit2PromotionalOfferPurchaseOptions: NSObject, Sendable {
    /// The id property of the subscription offer to apply.
    @objc public let offerID: String

    /// The JWS signature used to validate a promotional offer.
    @objc public let compactJWS: String

    /**
     * Creates a new ``StoreKit2PromotionalOfferPurchaseOptions`` instance.
     * - Parameters:
     *   - offerID: The id property of the subscription offer to apply.
     *   - compactJWS: The JWS signature used to validate a promotional offer.
     */
    @objc public init(
        offerID: String,
        compactJWS: String
    ) {
        self.offerID = offerID
        self.compactJWS = compactJWS
    }
}

#else

/**
 * ``StoreKit2PromotionalOfferPurchaseOptions`` can be used to apply promotional offers to StoreKit 2 purchases.
 */
@objc(StoreKit2PromotionalOfferPurchaseOptions)
internal final class StoreKit2PromotionalOfferPurchaseOptions: NSObject, Sendable {
    /// The id property of the subscription offer to apply.
    @objc let offerID: String

    /// The JWS signature used to validate a promotional offer.
    @objc let compactJWS: String

    /**
     * Creates a new ``StoreKit2PromotionalOfferPurchaseOptions`` instance.
     * - Parameters:
     *   - offerID: The id property of the subscription offer to apply.
     *   - compactJWS: The JWS signature used to validate a promotional offer.
     */
    @objc init(
        offerID: String,
        compactJWS: String
    ) {
        self.offerID = offerID
        self.compactJWS = compactJWS
    }
}

#endif
