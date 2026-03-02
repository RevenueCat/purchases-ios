//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchaseParams.swift
//
//  Created by mark on 17/10/24.

import Foundation

/**
 * ``PurchaseParams`` can be used to add configuration options when making a purchase.
 * This class follows the builder pattern.
 *
 * Example making a purchase using ``PurchaseParams``:
 *
 * ```swift
 * let params = PurchaseParams.Builder(package: package)
 *                            .with(metadata: ["key": "value"])
 *                            .with(promotionalOffer: promotionalOffer)
 *                            .build()
 * Purchases.shared.purchase(params)
 * ```
 */
@objc(RCPurchaseParams) public final class PurchaseParams: NSObject, Sendable {

    let package: Package?
    let product: StoreProduct?
    let promotionalOffer: PromotionalOffer?
    let quantity: Int?

    #if !ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION

    let winBackOffer: WinBackOffer?
    let metadata: [String: String]?

    #endif

    #if ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION

    let introductoryOfferEligibilityJWS: String?
    let promotionalOfferOptions: StoreKit2PromotionalOfferPurchaseOptions?

    #endif

    private init(with builder: Builder) {
        self.promotionalOffer = builder.promotionalOffer
        self.product = builder.product
        self.package = builder.package
        self.quantity = builder.quantity

        #if !ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION

        self.winBackOffer = builder.winBackOffer
        self.metadata = builder.metadata

        #endif

        #if ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION
        self.introductoryOfferEligibilityJWS = builder.introductoryOfferEligibilityJWS
        self.promotionalOfferOptions = builder.promotionalOfferOptions
        #endif
    }

    /// The Builder for ```PurchaseParams```.
    @objc(RCPurchaseParamsBuilder) public class Builder: NSObject {
        private(set) var promotionalOffer: PromotionalOffer?
        private(set) var package: Package?
        private(set) var product: StoreProduct?
        private(set) var quantity: Int?

        #if !ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION

        private(set) var winBackOffer: WinBackOffer?
        private(set) var metadata: [String: String]?

        #endif

        #if ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION

        private(set) var introductoryOfferEligibilityJWS: String?
        private(set) var promotionalOfferOptions: StoreKit2PromotionalOfferPurchaseOptions?

        #endif

        /**
         * Create a new builder with a ``Package``.
         *
         * - Parameter package: The ``Package`` the user intends to purchase.
         */
        @objc public init(package: Package) {
            self.package = package
        }

        /**
         * Create a new builder with a ``StoreProduct``.
         *
         * Use this initializer if you are not using the ``Offerings`` system to purchase a ``StoreProduct``.
         * If you are using the ``Offerings`` system, use ``PurchaseParams/Builder/init(package:)`` instead.
         *
         * - Parameter product: The ``StoreProduct`` the user intends to purchase.
         */
        @objc public init(product: StoreProduct) {
            self.product = product
        }

        /**
         * Set `promotionalOffer`.
         * - Parameter promotionalOffer: The ``PromotionalOffer`` to apply to the purchase.
         */
        @objc public func with(promotionalOffer: PromotionalOffer) -> Self {
            self.promotionalOffer = promotionalOffer
            return self
        }

        /**
         * Set `quantity`.
         * - Parameter quantity: The number of items to purchase. Must be between 1 and 10 (inclusive).
         *   If not specified, StoreKit will use its default quantity (typically 1).
         * - Throws: ``ErrorCode/purchaseInvalidError`` if quantity is less than 1 or greater than 10.
         */
        @objc public func with(quantity: Int) -> Self {
            self.quantity = quantity
            return self
        }

        #if !ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION

        #if ENABLE_TRANSACTION_METADATA
        /**
         * Set `metadata`.
         * - Parameter metadata: Key-value pairs of metadata to attatch to the purchase.
         */
        @objc public func with(metadata: [String: String]) -> Self {
            self.metadata = metadata
            return self
        }
        #endif

        /**
         * Sets a win-back offer for the purchase.
         * - Parameter winBackOffer: The ``WinBackOffer`` to apply to the purchase.
         *
         * Fetch a winBackOffer to use with this function with ``Purchases/eligibleWinBackOffers(forProduct:)``
         * or ``Purchases/eligibleWinBackOffers(forProduct:completion)``.
         *
         * Availability: iOS 18.0+, macOS 15.0+, tvOS 18.0+, watchOS 11.0+, visionOS 2.0+
         */
        @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
        @objc public func with(winBackOffer: WinBackOffer) -> Self {
            self.winBackOffer = winBackOffer
            return self
        }

        #endif

        #if ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION

        // swiftlint:disable line_length
        /**
         * Sets an introductoryOfferEligibility JWS to be included with the purchase. StoreKit 2 only.
         * - Parameter introductoryOfferEligibilityJWS: The ``introductoryOfferEligibilityJWS`` to apply to the purchase.
         *
         * Refer to https://developer.apple.com/documentation/storekit/product/purchaseoption/introductoryoffereligibility(compactjws:)
         * for more information.
         *
         * Availability: iOS 15.0+, macOS 15.4+, tvOS 18.4+, watchOS 11.4+, visionOS 2.4+
         */
        @available(iOS 15.0, macOS 15.4, tvOS 18.4, watchOS 11.4, visionOS 2.4, *)
        @objc public func with(introductoryOfferEligibilityJWS: String) -> Self {
            self.introductoryOfferEligibilityJWS = introductoryOfferEligibilityJWS
            return self
        }

        // swiftlint:disable line_length
        /**
         * Sets a promotionalOfferOptions to be included with the purchase. StoreKit 2 only.
         * - Parameter promotionalOfferOptions: The ``promotionalOfferOptions`` to apply to the purchase.
         *
         * Refer to https://developer.apple.com/documentation/storekit/product/purchaseoption/promotionaloffer(_:compactjws:)
         * for more information.
         *
         * Availability: iOS 15.0+, macOS 26.0+, tvOS 26.0+, watchOS 26.0+, visionOS 26.0+
         */
        @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
        @objc public func with(promotionalOfferOptions: StoreKit2PromotionalOfferPurchaseOptions) -> Self {
            self.promotionalOfferOptions = promotionalOfferOptions
            return self
        }

        #endif

        /// Generate a ``Configuration`` object given the values configured by this builder.
        @objc public func build() -> PurchaseParams {
            return PurchaseParams(with: self)
        }
    }
}
