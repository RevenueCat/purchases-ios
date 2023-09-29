//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StoreMessageType.swift
//
//  Created by Antonio Rico Diez on 27/9/23.

import StoreKit

/// Types of messages available in StoreKit
///
/// #### Related Symbols
/// - ``Purchases/showStoreMessages(forTypes:)``
@objc(RCStoreMessageType) public enum StoreMessageType: Int, CaseIterable, Sendable {
    /// Message shown when there are billing issues in a subscription
    case billingIssue = 0
    /// Message shown when there is a price increase in a subscription that requires consent
    case priceIncreaseConsent
    /// Generic Store messages
    case generic

    var numberValue: NSNumber {
        return NSNumber(value: self.rawValue)
    }
}

#if os(iOS)

@available(iOS 16.4, *)
@available(macOS, unavailable)
@available(watchOS, unavailable)
@available(tvOS, unavailable)
extension Message.Reason {
    var messageType: StoreMessageType? {
        switch self {
        // billingIssue message reason was added in iOS 16.4, but it's not recognized by older xcode versions.
        // https://developer.apple.com/documentation/xcode-release-notes/xcode-14_3-release-notes
        #if swift(>=5.8)
        case .billingIssue: return .billingIssue
        #endif
        case .priceIncreaseConsent: return .priceIncreaseConsent
        case .generic: return .generic
        default:
            Logger.error("Unrecognized Message.Reason: \(self)")
            return nil
        }
    }
}

#endif
