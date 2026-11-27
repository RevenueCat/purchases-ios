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

/// The outcome of preparing one promotional offer. Exactly one of `offer` and `error` is non-nil.
@objc(RCPromotionalOfferResult)
@_spi(Internal) public final class PromotionalOfferResult: NSObject, Sendable {

    /// The original request, including the product and discount this result belongs to.
    @objc public let request: PromotionalOfferRequest
    /// The signed offer, ready to pass to a purchase, or `nil` if preparation failed.
    @objc public let offer: PromotionalOffer?
    /// The error that prevented preparing this offer, or `nil` on success.
    @objc public let error: PublicError?

    init(request: PromotionalOfferRequest, result: Result<PromotionalOffer, PurchasesError>) {
        self.request = request
        self.offer = result.value
        self.error = result.error?.asPublicError
        super.init()
    }

}
