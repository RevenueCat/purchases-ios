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

#if ENABLE_CONFIGURED_AD_REWARDS
var configuredAdRewards: ConfiguredAdRewards!
var adRewardConfiguration: AdRewardConfiguration!
var virtualCurrencyRewardConfiguration: VirtualCurrencyRewardConfiguration!
var entitlementRewardConfiguration: EntitlementRewardConfiguration!
var adRewardDuration: AdRewardDuration!
#endif

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

#if ENABLE_CONFIGURED_AD_REWARDS

func checkConfiguredAdRewardsAPI() {
    let _: AdRewardConfiguration = configuredAdRewards.configuredReward
    let _: [AdRewardConfiguration] = configuredAdRewards.moreRewards
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
    let _: AdRewardDuration = entitlementRewardConfiguration.duration
}

func checkAdRewardDurationAPI() {
    let _: Int = adRewardDuration.value
    let _: AdRewardDuration.Unit = adRewardDuration.unit
    let _: String = adRewardDuration.unit.rawValue
    let _: AdRewardDuration.Unit = .second
    let _: AdRewardDuration.Unit = .minute
    let _: AdRewardDuration.Unit = .hour
    let _: AdRewardDuration.Unit = .day
    let _: AdRewardDuration.Unit = .week
    let _: AdRewardDuration.Unit = .month
    let _: AdRewardDuration.Unit = .year
}

#endif
