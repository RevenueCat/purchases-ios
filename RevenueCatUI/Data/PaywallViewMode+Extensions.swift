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
        case .card: return true
        case .condensedCard: return false
        }
    }

    var displayAllPlansButton: Bool {
        switch self {
        case .fullScreen: return false
        case .card: return false
        case .condensedCard: return true
        }
    }

    var shouldDisplayIcon: Bool {
        switch self {
        case .fullScreen: return true
        case .card, .condensedCard: return false
        }
    }

    var shouldDisplayText: Bool {
        switch self {
        case .fullScreen: return true
        case .card, .condensedCard: return false
        }
    }

    var shouldDisplayFeatures: Bool {
        switch self {
        case .fullScreen: return true
        case .card, .condensedCard: return false
        }
    }

}
