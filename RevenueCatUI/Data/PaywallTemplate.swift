//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallTemplate.swift
//
//  Created by Nacho Soto on 7/10/23.

import Foundation

/// The type of template used to display a paywall.
internal enum PaywallTemplate: String {

    case template1 = "1"
    case template2 = "2"
    case template3 = "3"

    // Temporarily disabled until it's supported in the dashboard
    case template4 = "4_disabled"
    case template5 = "5_disabled"

}

extension PaywallTemplate: Equatable {}
extension PaywallTemplate: CaseIterable {}
