//
//  EntitlementInfoEnums.swift
//  PurchasesCoreSwift
//
//  Created by Joshua Liebowitz on 6/24/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

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
}

/**
 Enum of supported period types for an entitlement.
 */
@objc(RCPeriodType) public enum PeriodType: Int {
    /// If the entitlement is not under an introductory or trial period.
    @objc(RCNormal) case normal = 0
    /// If the entitlement is under a introductory price period.
    @objc(RCIntro) case intro = 1
    /// If the entitlement is under a trial period.
    @objc(RCTrial) case trial = 2
}
