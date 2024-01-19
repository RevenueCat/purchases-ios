//
//  PaywallViewConfiguration.swift
//
//
//  Created by Nacho Soto on 1/19/24.
//

import Foundation

import RevenueCat

/// Parameters needed to configure a ``PaywallView``.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct PaywallViewConfiguration {

    var offering: Offering?
    var customerInfo: CustomerInfo?
    var mode: PaywallViewMode = .default
    var fonts: PaywallFontProvider = DefaultPaywallFontProvider()
    var displayCloseButton: Bool = false
    var introEligibility: TrialOrIntroEligibilityChecker?
    var purchaseHandler: PurchaseHandler?

}
