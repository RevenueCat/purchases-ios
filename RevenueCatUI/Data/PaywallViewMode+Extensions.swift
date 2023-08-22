//
//  PaywallViewMode+Extensions.swift
//  
//
//  Created by Nacho Soto on 8/9/23.
//

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

}
