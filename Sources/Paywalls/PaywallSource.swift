//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallSource.swift
//
//  Created by RevenueCat on 2/26/25.

import Foundation

/// Identifies where a paywall was presented from so that backend analytics can classify the event.
@_spi(Internal) public enum PaywallSource: String, Sendable, Codable {

    /// The paywall was presented from Customer Center.
    case customerCenter = "customer_center"

}
