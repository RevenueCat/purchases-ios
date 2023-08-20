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
        case .overlay: return true
        case .condensedOverlay: return false
        }
    }

    var displayAllPlansButton: Bool {
        switch self {
        case .fullScreen: return false
        case .overlay: return false
        case .condensedOverlay: return true
        }
    }

    var shouldDisplayIcon: Bool {
        switch self {
        case .fullScreen: return true
        case .overlay, .condensedOverlay: return false
        }
    }

    var shouldDisplayText: Bool {
        switch self {
        case .fullScreen: return true
        case .overlay, .condensedOverlay: return false
        }
    }

    var shouldDisplayFeatures: Bool {
        switch self {
        case .fullScreen: return true
        case .overlay, .condensedOverlay: return false
        }
    }

}
