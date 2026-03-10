//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchaseSource.swift

import Foundation

/// Identifies where a non-paywall purchase was initiated from so that backend analytics
/// can classify the transaction origin.
@_spi(Internal) public enum PurchaseSource: String, Sendable, Codable {

    /// The purchase was initiated from Customer Center (e.g. a promotional offer).
    case customerCenter = "customer_center"

}
