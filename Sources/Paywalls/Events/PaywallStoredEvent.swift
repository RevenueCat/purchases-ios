//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallStoredEvent.swift
//
//  Created by Nacho Soto on 9/6/23.

import Foundation

/// Contains the necessary information for `PaywallEventStore`.
struct PaywallStoredEvent {

    var event: PaywallEvent
    var userID: String

}

// MARK: - Extensions

extension PaywallStoredEvent: Equatable, Sendable {}

extension PaywallStoredEvent: Codable {

    private enum CodingKeys: String, CodingKey {

        case event
        case userID = "userId"

    }

}
