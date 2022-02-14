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
/// - ``Purchases/getPromotionalOffer(forProductDiscount:product:)``
/// - ``Purchases/getPromotionalOffer(forProductDiscount:product:completion:)``
/// - ``StoreProduct/getEligiblePromotionalOffers()``
/// - ``Purchases/getEligiblePromotionalOffers(forProduct:)``
/// - ``Purchases/purchase(package:promotionalOffer:)``
/// - ``Purchases/purchase(package:promotionalOffer:completion:)``
/// - ``Purchases/purchase(product:promotionalOffer:)``
/// - ``Purchases/purchase(product:promotionalOffer:completion:)``
@objc(RCPromotionalOffer)
public final class PromotionalOffer: NSObject {

    /// The ``StoreProductDiscount`` in this offer.
    public let discount: StoreProductDiscount
    let signedData: SignedData

    init(discount: StoreProductDiscountType, signedData: SignedData) {
        self.discount = StoreProductDiscount.from(discount: discount)
        self.signedData = signedData
    }

}

// MARK: - SignedData

extension PromotionalOffer {

    /// Contains the details of a promotional offer discount that you want to apply to a payment.
    internal struct SignedData {
        var identifier: String
        var keyIdentifier: String
        var nonce: UUID
        var signature: String
        var timestamp: Int
    }

}

extension PromotionalOffer.SignedData {

    @available(iOS 12.2, macOS 10.14.4, watchOS 6.2, macCatalyst 13.0, tvOS 12.2, *)
    var sk1PromotionalOffer: SKPaymentDiscount {
        return SKPaymentDiscount(identifier: self.identifier,
                                 keyIdentifier: self.keyIdentifier,
                                 nonce: self.nonce,
                                 signature: self.signature,
                                 timestamp: self.timestamp as NSNumber)
    }

    /// - Throws: ``ErrorCode/unexpectedBackendResponseError`` if the signature cannot be encoded in UTF8
    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    var sk2PurchaseOption: Product.PurchaseOption {
        get throws {
            guard let signatureData = self.signature.data(using: .utf8) else {
                throw ErrorUtils.unexpectedBackendResponse(
                    withSubError: PromotionalOffer.Error.invalidSignature(self.signature)
                )
            }

            return .promotionalOffer(
                offerID: self.identifier,
                keyID: self.keyIdentifier,
                nonce: self.nonce,
                signature: signatureData,
                timestamp: self.timestamp
            )
        }
    }

}

extension PromotionalOffer {

    enum Error: DescribableError {

        case invalidSignature(String)

        var description: String {
            switch self {
            case let .invalidSignature(signature):
                return "PromotionalOffer.signature cannot be encoded in UTF8: '\(signature)'"
            }
        }

    }

}
