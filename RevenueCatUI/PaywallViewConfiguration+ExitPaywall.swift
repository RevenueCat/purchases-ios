//
//  PaywallViewConfiguration+ExitPaywall.swift
//  RevenueCatUI
//
//  Created by GPT-5.1 Codex on 2025-12-03.
//

import RevenueCat

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension PaywallViewConfiguration {

    /// Additional metadata describing a follow-up paywall to present after dismissal.
    var exitPaywallContent: Content? {
        return self.content.exitPaywallContent
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension PaywallViewConfiguration.Content {

    var exitPaywallContent: PaywallViewConfiguration.Content? {
        switch self {
        case let .offering(offering):
            return offering.exitPaywallContent
        default:
            return nil
        }
    }

}
