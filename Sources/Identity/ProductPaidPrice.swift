//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ProductPaidPrice.swift
//
//  Created by Facundo Menzella on 15/1/25.

import Foundation

/// Price paid for the product
@objc(RCProductPaidPrice) public final class ProductPaidPrice: NSObject, Sendable {

    /// Currency paid
    @objc public let currency: String

    /// Amount paid
    @objc public let amount: Double

    /// ProductPaidPrice initialiser
    /// - Parameters:
    ///   - currency: Currency paid
    ///   - amount: Amount paid
    public init(currency: String, amount: Double) {
        self.currency = currency
        self.amount = amount
    }
}
