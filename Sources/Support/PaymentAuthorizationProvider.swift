//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaymentAuthorizationProvider.swift
//
//  Created by Pol Piella Abadia on 23/06/2025.

import Foundation
import StoreKit

struct PaymentAuthorizationProvider {
    var isAuthorized: () -> Bool
}

extension PaymentAuthorizationProvider {
    static let storeKit = PaymentAuthorizationProvider(
        isAuthorized: {
            if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *) {
                return AppStore.canMakePayments
            } else {
                return SKPaymentQueue.canMakePayments()
            }
        }
    )
}
