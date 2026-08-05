//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Checkpoint.swift
//
//  Created by Rick van der Linden.
//

@_spi(Internal) import RevenueCat

// These aliases temporarily surface the Core-owned checkpoint models from RevenueCatUI.
// Revisit module ownership and whether aliases are desirable before making this API public.

/// Core-owned checkpoint custom value, surfaced through RevenueCatUI.
@_spi(Internal) public typealias CheckpointValue = RevenueCat.CheckpointValue
/// Core-owned checkpoint parameters, surfaced through RevenueCatUI.
@_spi(Internal) public typealias CheckpointParams = RevenueCat.CheckpointParams
/// Core-owned checkpoint information, surfaced through RevenueCatUI.
@_spi(Internal) public typealias CheckpointInfo = RevenueCat.CheckpointInfo
/// Core-owned no-action reason, surfaced through RevenueCatUI.
@_spi(Internal) public typealias CheckpointNoActionReason = RevenueCat.CheckpointNoActionReason
/// Core-owned checkpoint result, surfaced through RevenueCatUI.
@_spi(Internal) public typealias CheckpointResult = RevenueCat.CheckpointResult
/// Core-owned presented-paywall result, surfaced through RevenueCatUI.
@_spi(Internal) public typealias CheckpointPaywallPresentedResult = RevenueCat.CheckpointPaywallPresentedResult
/// Core-owned no-action result, surfaced through RevenueCatUI.
@_spi(Internal) public typealias CheckpointNoActionResult = RevenueCat.CheckpointNoActionResult
/// Core-owned paywall outcome, surfaced through RevenueCatUI.
@_spi(Internal) public typealias CheckpointPaywallOutcome = RevenueCat.CheckpointPaywallOutcome
/// Core-owned dismissed outcome, surfaced through RevenueCatUI.
@_spi(Internal) public typealias CheckpointPaywallDismissedOutcome = RevenueCat.CheckpointPaywallDismissedOutcome
/// Core-owned purchased outcome, surfaced through RevenueCatUI.
@_spi(Internal) public typealias CheckpointPaywallPurchasedOutcome = RevenueCat.CheckpointPaywallPurchasedOutcome
/// Core-owned restored outcome, surfaced through RevenueCatUI.
@_spi(Internal) public typealias CheckpointPaywallRestoredOutcome = RevenueCat.CheckpointPaywallRestoredOutcome
/// Core-owned error outcome, surfaced through RevenueCatUI.
@_spi(Internal) public typealias CheckpointPaywallErrorOutcome = RevenueCat.CheckpointPaywallErrorOutcome
/// Core-owned checkpoint listener, surfaced through RevenueCatUI.
@_spi(Internal) public typealias CheckpointListener = RevenueCat.CheckpointListener
