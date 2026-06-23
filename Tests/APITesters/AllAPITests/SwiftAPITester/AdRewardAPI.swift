//
//  AdRewardAPI.swift
//  SwiftAPITester
//

import Foundation
@_spi(Experimental) import RevenueCat

var adReward: AdReward!
var virtualCurrencyReward: VirtualCurrencyReward!
var entitlementReward: EntitlementReward!

func checkAdRewardAPI() {
    let _: VirtualCurrencyReward? = adReward.virtualCurrency
    let _: EntitlementReward? = adReward.entitlement
    let _: AdReward = .noReward
    let _: AdReward = .unsupportedReward
    let _: Bool = adReward == .noReward
}

func checkVirtualCurrencyRewardAPI() {
    let _: String = virtualCurrencyReward.code
    let _: Int = virtualCurrencyReward.amount
}

func checkEntitlementRewardAPI() {
    let _: String = entitlementReward.identifier
    let _: Date = entitlementReward.expiresAt
}
