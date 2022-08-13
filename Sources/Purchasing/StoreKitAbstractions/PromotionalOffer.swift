//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PromotionalOffer.swift
//
//  Created by Josh Holtz on 1/18/22.

import Foundation
import StoreKit

/// Represents a ``StoreProductDiscount`` that has been validated and
/// is ready to be used for a purchase.
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
@objc(RCPromotionalOffer)
public final class PromotionalOffer: NSObject {

    /// The ``StoreProductDiscount`` in this offer.
    @objc public let discount: StoreProductDiscount
    /// The ``SignedData-swift.class`` provides information about the ``PromotionalOffer``'s signature.
    @objc public let signedData: SignedData

    init(discount: StoreProductDiscountType, signedData: SignedData) {
        self.discount = StoreProductDiscount.from(discount: discount)
        self.signedData = signedData
    }

}

extension PromotionalOffer: Sendable {}

// MARK: - SignedData

@objc public extension PromotionalOffer {

    /// Contains the details of a promotional offer discount that you want to apply to a payment.
    @objc(RCPromotionalOfferSignedData)
    final class SignedData: NSObject {
        /// The subscription offer identifier.
        @objc public let identifier: String
        /// The key identifier of the subscription key.
        @objc public let keyIdentifier: String
        /// The nonce used in the signature.
        @objc public let nonce: UUID
        /// The cryptographic signature of the offer parameters, generated on RevenueCat's server.
        @objc public let signature: String
        /// The UNIX time, in milliseconds, when the signature was generated.
        @objc public let timestamp: Int

        init(identifier: String, keyIdentifier: String, nonce: UUID, signature: String, timestamp: Int) {
            self.identifier = identifier
            self.keyIdentifier = keyIdentifier
            self.nonce = nonce
            self.signature = signature
            self.timestamp = timestamp
        }
    }

}

#if swift(>=5.7)
extension PromotionalOffer.SignedData: Sendable {}
#else
// `@unchecked` because:
// - `UUID` is not `Sendable` until Swift 5.7
extension PromotionalOffer.SignedData: @unchecked Sendable {}
#endif

extension PromotionalOffer.SignedData {

    @available(iOS 12.2, macOS 10.14.4, watchOS 6.2, macCatalyst 13.0, tvOS 12.2, *)
    var sk1PromotionalOffer: SKPaymentDiscount {
        return SKPaymentDiscount(identifier: self.identifier,
                                 keyIdentifier: self.keyIdentifier,
                                 nonce: self.nonce,
                                 signature: self.signature,
                                 timestamp: self.timestamp as NSNumber)
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    var sk2PurchaseOption: Product.PurchaseOption {
        return .promotionalOffer(
            offerID: self.identifier,
            keyID: self.keyIdentifier,
            nonce: self.nonce,
            signature: self.signature.asData,
            timestamp: self.timestamp
        )
    }

}
