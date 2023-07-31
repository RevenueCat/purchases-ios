//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  FrameworkDisambiguation.swift
//
//  Created by Nacho Soto on 4/25/23.w

/**
 Purpose: this file is needed because several parts of the SDK need to explicitily reference a type or value
 from the `RevenueCat` target. However, we expose 2 variants of the framework from SPM:
 `RevenueCat` and `RevenueCat_CustomEntitlementComputation` (see `Package.swift`).
  Because of that, we can't simply do `RevenueCat.ErrorCode` for example, since the other variant
  would need `RevenueCat_CustomEntitlementComputation.ErrorCode`.

  To handle that, this exposes those types explicitly so they work regardless of the name of the framework.
 */

typealias RCRefundRequestStatus = RefundRequestStatus
typealias RCErrorCode = ErrorCode
typealias RCOffering = Offering
typealias RCStorefront = Storefront

let RCDefaultLogHandler = defaultLogHandler
