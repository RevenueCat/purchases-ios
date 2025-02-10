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

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

#if !ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION

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
    let winBackOffer: WinBackOffer?
    let metadata: [String: String]?

    /// Options for the confirmIn: parameter of the `purchase(confirmIn:options:)` SK2 APIs.
    let sk2ConfirmInOptions: SK2ConfirmInOptions?

    private init(with builder: Builder) {
        self.promotionalOffer = builder.promotionalOffer
        self.metadata = builder.metadata
        self.product = builder.product
        self.package = builder.package
        self.winBackOffer = builder.winBackOffer
        self.sk2ConfirmInOptions = builder.sk2ConfirmInOptions
    }

    /// The Builder for ```PurchaseParams```.
    @objc(RCPurchaseParamsBuilder) public class Builder: NSObject {
        private(set) var promotionalOffer: PromotionalOffer?
        private(set) var metadata: [String: String]?
        private(set) var package: Package?
        private(set) var product: StoreProduct?
        private(set) var winBackOffer: WinBackOffer?
        private(set) var sk2ConfirmInOptions: SK2ConfirmInOptions?

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

        #if canImport(UIKit) && !os(watchOS)
        /**
         * Set `confirmInScene`.
         *
         * - Parameter confirmInScene: The scene to show the purchase confirmation UI in proximity to.
         * - Note: This value is only used when StoreKit 2 is in use.
         *
         * Availability: iOS 17.0+, macCatalyst 15.0+, tvOS 17.0+, visionOS 1.0+
         */
        @available(iOS 17.0, macCatalyst 15.0, tvOS 17.0, visionOS 1.0, *)
        @objc public func with(confirmInScene: UIScene) -> Self {
            self.sk2ConfirmInOptions = SK2ConfirmInOptions(confirmInScene: confirmInScene)
            return self
        }
        #endif

        #if canImport(AppKit)
        /**
         * Set `confirmInWindow`.
         *
         * - Parameter confirmInWindow: The window to show the purchase confirmation UI in proximity to.
         * - Note: This value is only used when StoreKit 2 is in use.
         *
         * Availability: macOS 15.2+
         */
        @available(macOS 15.2, *)
        @objc public func with(confirmInWindow: NSWindow) -> Self {
            self.sk2ConfirmInOptions = SK2ConfirmInOptions(confirmInWindow: confirmInWindow)
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

        /// Generate a ``Configuration`` object given the values configured by this builder.
        @objc public func build() -> PurchaseParams {
            return PurchaseParams(with: self)
        }
    }
}

#endif
