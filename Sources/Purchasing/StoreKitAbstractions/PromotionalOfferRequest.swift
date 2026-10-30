//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//

import Foundation

/// A promotional discount and the product for which to prepare a signed offer.
@objc(RCPromotionalOfferRequest)
@_spi(Internal) public final class PromotionalOfferRequest: NSObject, Sendable {

    /// The promotional discount to sign, obtained from ``StoreProduct/discounts``.
    @objc public let discount: StoreProductDiscount
    /// The product to which the discount belongs.
    @objc public let product: StoreProduct

    /// Creates a request for a promotional discount belonging to `product`.
    @_spi(Internal) @objc public init(discount: StoreProductDiscount, product: StoreProduct) {
        self.discount = discount
        self.product = product
        super.init()
    }

}
