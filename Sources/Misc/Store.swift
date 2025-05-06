//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PlatformInfo.swift
//
//  Created by Toni Rico on 5/5/25.

import Foundation

/**
 Enum of supported stores
 */
@objc(RCStore) public enum Store: Int {

    /// For entitlements granted via Apple App Store.
    @objc(RCAppStore) case appStore = 0

    /// For entitlements granted via Apple Mac App Store.
    @objc(RCMacAppStore) case macAppStore = 1

    /// For entitlements granted via Google Play Store.
    @objc(RCPlayStore) case playStore = 2

    /// For entitlements granted via Stripe.
    @objc(RCStripe) case stripe = 3

    /// For entitlements granted via a promo in RevenueCat.
    @objc(RCPromotional) case promotional = 4

    /// For entitlements granted via an unknown store.
    @objc(RCUnknownStore) case unknownStore = 5

    /// For entitlements granted via the Amazon Store.
    @objc(RCAmazon) case amazon = 6

    /// For entitlements granted via RevenueCat's Web Billing
    @objc(RCBilling) case rcBilling = 7

    /// For entitlements granted via RevenueCat's External Purchases API.
    @objc(RCExternal) case external = 8

}

extension Store: CaseIterable {}
extension Store: Sendable {}

extension Store: DefaultValueProvider {

    static let defaultValue: Self = .unknownStore

}
