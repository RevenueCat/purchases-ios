//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Transaction+AcceptedOffer.swift
//
//  Created by Facundo Menzella on 12/5/25.

import RevenueCat
import StoreKit

#if os(iOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension StoreKit.Transaction {

    var acceptedOffer: AppliedTransactionOffer? {
        if #available(iOS 17.2, *) {
            return AppliedTransactionOffer(from: self.offer)
        } else if let offerType {
            print(offerPaymentModeStringRepresentation)

            return AppliedTransactionOffer(
                id: offerID,
                type: offerType.discountType,
                paymentMode: nil,
                period: nil // TOOD: offerPaymentModeStringRepresentation
            )

        } else {
            return nil
        }
    }
}

#endif
