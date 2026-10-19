//
//  AdRewardAPI.swift
//  SwiftAPITester
//

import Foundation
import RevenueCat

var adReward: AdReward!
var virtualCurrencyReward: VirtualCurrencyReward!
var entitlementReward: EntitlementReward!
var rewardVerificationResult: RewardVerificationResult!

var configuredAdRewards: ConfiguredAdRewards!
var adRewardConfiguration: AdRewardConfiguration!
var virtualCurrencyRewardConfiguration: VirtualCurrencyRewardConfiguration!
var entitlementRewardConfiguration: EntitlementRewardConfiguration!

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

func checkRewardVerificationResultAPI() {
    let _: AdReward? = rewardVerificationResult.verifiedReward
    let _: [AdReward] = rewardVerificationResult.moreRewards
    let _: RewardVerificationResult = .failed
}

func checkConfiguredAdRewardsAPI() {
    let _: AdRewardConfiguration? = configuredAdRewards.reward
    let _: [AdRewardConfiguration] = configuredAdRewards.moreRewards
    let _: ConfiguredAdRewards = .noConfiguredReward
    let _: Bool = configuredAdRewards == .noConfiguredReward
}

func checkAdRewardConfigurationAPI() {
    let _: VirtualCurrencyRewardConfiguration? = adRewardConfiguration.virtualCurrency
    let _: EntitlementRewardConfiguration? = adRewardConfiguration.entitlement
    let _: AdRewardConfiguration = .unsupportedReward
}

func checkVirtualCurrencyRewardConfigurationAPI() {
    let _: String = virtualCurrencyRewardConfiguration.code
    let _: Int = virtualCurrencyRewardConfiguration.amount
}

func checkEntitlementRewardConfigurationAPI() {
    let _: String = entitlementRewardConfiguration.identifier
    let _: TimeInterval = entitlementRewardConfiguration.duration
}
