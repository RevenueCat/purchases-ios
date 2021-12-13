//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SKProduct+Extensions.swift
//
//  Created by Nacho Soto on 12/13/21.

import StoreKit

extension SK1Product {
    /// Attempts to find a non-nil `productIdentifier`.
    ///
    /// Although both `SK1Product.productIdentifier` and `SKPayment.productIdentifier`
    /// are supposed to be non-nil, we've seen instances where this is not true.
    /// so we cast into optionals in order to check nullability, and try to fall back if possible.
    func extractProductIdentifier(withPayment payment: SKPayment,
                                  fileName: String = #fileID,
                                  functionName: String = #function,
                                  line: UInt = #line) -> String? {
        if let identifierFromProduct = self.productIdentifier as String?,
           !identifierFromProduct.trimmingWhitespacesAndNewLines.isEmpty {
            return identifierFromProduct
        }
        Logger.appleWarning(Strings.purchase.product_identifier_nil,
                            fileName: fileName, functionName: functionName, line: line)

        if let identifierFromPayment = payment.productIdentifier as String?,
           !identifierFromPayment.trimmingWhitespacesAndNewLines.isEmpty {
            return identifierFromPayment
        }
        Logger.appleWarning(Strings.purchase.payment_identifier_nil,
                            fileName: fileName, functionName: functionName, line: line)

        return nil
    }
}
