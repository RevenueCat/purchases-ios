//
//  AdRewardAPI.swift
//  SwiftAPITester
//

import Foundation
@_spi(Experimental) import RevenueCat

func checkAdRewardAPI(reward: AdReward) {
    let _: VirtualCurrencyReward? = reward.virtualCurrency
    let _: EntitlementReward? = reward.entitlement
    let _: AdReward = .noReward
    let _: AdReward = .unsupportedReward
    let _: Bool = reward == .noReward
}

func checkVirtualCurrencyRewardAPI(reward: VirtualCurrencyReward) {
    let _: String = reward.code
    let _: Int = reward.amount
}

func checkEntitlementRewardAPI(reward: EntitlementReward) {
    let _: String = reward.identifier
    let _: Date = reward.expiresAt
}
