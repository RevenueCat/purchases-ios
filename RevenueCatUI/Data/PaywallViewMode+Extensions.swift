//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallViewMode+Extensions.swift
//
//  Created by Nacho Soto on 8/9/23.

import RevenueCat

extension PaywallViewMode {

    var displayAllPlansByDefault: Bool {
        switch self {
        case .fullScreen: return true
        case .footer: return true
        case .condensedFooter: return false
        }
    }

    var displayAllPlansButton: Bool {
        switch self {
        case .fullScreen: return false
        case .footer: return false
        case .condensedFooter: return true
        }
    }

    var shouldDisplayIcon: Bool {
        switch self {
        case .fullScreen: return true
        case .footer, .condensedFooter: return false
        }
    }

    var shouldDisplayText: Bool {
        switch self {
        case .fullScreen: return true
        case .footer, .condensedFooter: return false
        }
    }

    var shouldDisplayFeatures: Bool {
        switch self {
        case .fullScreen: return true
        case .footer, .condensedFooter: return false
        }
    }

    var shouldDisplayBackground: Bool {
        switch self {
        case .fullScreen: return true
        case .footer, .condensedFooter: return false
        }
    }

}
